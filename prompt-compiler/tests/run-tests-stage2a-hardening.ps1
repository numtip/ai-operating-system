<#
.SYNOPSIS
  Deterministic tests for Stage 2A secret loader + preflight hardening.
  Uses a THROWAWAY external secret file under $env:TEMP — never the real one,
  never a real key, never the repo.
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File prompt-compiler/tests/run-tests-stage2a-hardening.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = [string](Resolve-Path (Join-Path $PSScriptRoot '../..'))
$loader = Join-Path $Root 'prompt-compiler/runtime/Secret-Loader.ps1'
$telemetry = Join-Path $Root 'prompt-compiler/runtime/Cost-Telemetry.ps1'
. $loader
. $telemetry

$passed = 0
$failed = 0

function Assert-True {
    param([string]$Name, [bool]$Condition, [string]$Detail = '')
    if ($Condition) {
        $script:passed++
        Write-Host "PASS  $Name"
    }
    else {
        $script:failed++
        Write-Host "FAIL  $Name  $Detail"
    }
}

# Throwaway external secret file (fake key, never real)
$tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ('aios-stage2a-test-' + [guid]::NewGuid().ToString('N'))
$tmpSecret = Join-Path $tmpDir 'stage2a.env'
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
# Dynamic fixture key — never a literal in repo source, never a real key
$fakeKey = 'sk-stage2a-fixture-' + [guid]::NewGuid().ToString('N')
try {
    [System.IO.File]::WriteAllText($tmpSecret, "# fixture`nDEEPSEEK_API_KEY=$fakeKey`n")

    # --- 1. file detection ---
    Assert-True '1a.secret_file_exists' (Test-ExternalSecretFile -Path $tmpSecret)
    Assert-True '1b.secret_file_missing' (-not (Test-ExternalSecretFile -Path (Join-Path $tmpDir 'nope.env')))

    # --- 2. key presence (value never surfaced) ---
    Assert-True '2a.key_present' (Test-ExternalKeyPresent -Path $tmpSecret -KeyName 'DEEPSEEK_API_KEY')
    Assert-True '2b.key_name_missing' (-not (Test-ExternalKeyPresent -Path $tmpSecret -KeyName 'OPENAI_API_KEY'))

    # --- 3. env map loads without printing; no repo .env dependency ---
    $map = Get-ExternalSecretEnv -Path $tmpSecret
    Assert-True '3a.env_map_loaded' ($map['DEEPSEEK_API_KEY'] -eq $fakeKey)
    # loader source must not reference a repo-local .env
    $src = [System.IO.File]::ReadAllText($loader)
    Assert-True '3b.loader_no_repo_env_dependency' ($src -notmatch 'ai-operating-system[\\/]\.env') 'loader must not require repo .env'

    # --- 4. leak scan: fake key not in repo -> clean; planted copy -> hit ---
    Assert-True '4a.no_leak_fresh_repo' (-not (Test-KeyLeakedInRepo -KeyValue $fakeKey -RepoRoot $Root))
    $leakFile = Join-Path $Root 'evidence-leak-test.txt'
    [System.IO.File]::WriteAllText($leakFile, "leak $fakeKey here")
    try {
        Assert-True '4b.leak_detected' (Test-KeyLeakedInRepo -KeyValue $fakeKey -RepoRoot $Root)
    }
    finally {
        Remove-Item -LiteralPath $leakFile -Force -ErrorAction SilentlyContinue
    }

    # --- 5. preflight behavior matrix (throwaway file) ---
    $pfOk = Invoke-Stage2aPreflight -SecretPath $tmpSecret -RepoRoot $Root
    Assert-True '5a.preflight_pass_with_key' ($pfOk.ok -and $pfOk.verdict -eq 'READY_FOR_LIVE_RUN') "verdict=$($pfOk.verdict)"
    Assert-True '5b.preflight_never_returns_key' (-not (($pfOk | ConvertTo-Json -Depth 5).Contains($fakeKey)))
    Assert-True '5c.preflight_check_count' (@($pfOk.checks).Count -eq 4)

    $emptyFile = Join-Path $tmpDir 'empty.env'
    [System.IO.File]::WriteAllText($emptyFile, 'DEEPSEEK_API_KEY=' + "`n")
    $pfEmpty = Invoke-Stage2aPreflight -SecretPath $emptyFile -RepoRoot $Root
    Assert-True '5d.preflight_blocks_empty_key' (-not $pfEmpty.ok -and $pfEmpty.verdict -eq 'BLOCKED')

    $pfMissing = Invoke-Stage2aPreflight -SecretPath (Join-Path $tmpDir 'absent.env') -RepoRoot $Root
    Assert-True '5e.preflight_blocks_missing_file' (-not $pfMissing.ok)

    # --- 6. run config ---
    $cfg = Get-Stage2aRunConfig -RepoRoot $Root
    Assert-True '6a.config_model' ($cfg.model -eq 'deepseek-v4-flash')
    Assert-True '6b.config_caps_positive' ([double]$cfg.cap_usd -gt 0 -and [long]$cfg.cap_total_tokens -gt 0 -and [int]$cfg.max_output_tokens -gt 0)

    # --- 7. redaction integration (Cost-Telemetry) ---
    $red = ConvertTo-CostRedactedText -Text "api_key = $fakeKey Bearer $fakeKey"
    Assert-True '7a.redaction_masks_key' ($red -notmatch $fakeKey -and $red -match 'REDACTED') "red=$red"

    Write-Host ''
    Write-Host ("STAGE-2A-HARDENING SUMMARY passed={0} failed={1}" -f $passed, $failed)
    if ($failed -gt 0) { exit 1 } else { exit 0 }
}
finally {
    if (Test-Path -LiteralPath $tmpDir) { Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue }
}
