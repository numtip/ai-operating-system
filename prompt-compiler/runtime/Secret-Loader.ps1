<#
.SYNOPSIS
  AI-OS Stage 2A Secret Loader + Preflight (v0.1) — external-file only, no logging.
.DESCRIPTION
  Secrets for the bounded live test are loaded ONLY from an owner-only file
  OUTSIDE the repository:  %LOCALAPPDATA%\AI-OS\stage2a.env

  This module never requires a repo-local .env, never logs environment values,
  and only exposes "present/non-empty" facts (never the value).

  Loader contract (security):
    - Read values only when constructing the environment for a child process.
    - Never Write-Host / log / persist any environment value.
    - Repo code must not require a repo-local ".env" file (secrets live outside).

  Functions:
    Get-ExternalSecretPath       : resolved path of the external secret file
    Test-ExternalSecretFile      : file exists?
    Get-ExternalSecretEnv        : hashtable of key=value (caller sets child env; no logging)
    Test-ExternalKeyPresent      : DEEPSEEK_API_KEY non-empty? (value never printed)
    Invoke-Stage2aPreflight      : all pre-flight checks, value-safe result
    Get-Stage2aRunConfig         : run config (model/caps) from repo JSON
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:SecretLoaderVersion = '0.1.0'
$script:DefaultSecretFileName = 'stage2a.env'
$script:DefaultRunConfigRel = 'prompt-compiler/runtime/stage2a-run-config.json'
$script:DefaultModel = 'deepseek-v4-flash'

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

function Get-ExternalSecretPath {
    param([string]$Path = '')
    if ($Path) { return [System.IO.Path]::GetFullPath($Path) }
    $dir = Join-Path $env:LOCALAPPDATA 'AI-OS'
    return (Join-Path $dir $script:DefaultSecretFileName)
}

function Get-Stage2aRepoRoot {
    $here = $PSScriptRoot
    if (-not $here) { $here = Split-Path -Parent $MyInvocation.MyCommand.Path }
    return [string](Resolve-Path (Join-Path $here '..\..'))
}

function Test-ExternalSecretFile {
    param([string]$Path = '')
    return (Test-Path -LiteralPath (Get-ExternalSecretPath -Path $Path) -PathType Leaf)
}

# ---------------------------------------------------------------------------
# Loader — read ONLY for child-process env construction; never log values
# ---------------------------------------------------------------------------

function Get-ExternalSecretEnv {
    param([string]$Path = '')
    $full = Get-ExternalSecretPath -Path $Path
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        throw "external secret file not found: $full (owner must create it outside the repo)"
    }
    $map = @{}
    foreach ($line in [System.IO.File]::ReadAllLines($full)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $trim = $line.Trim()
        if ($trim.StartsWith('#')) { continue }
        $idx = $trim.IndexOf('=')
        if ($idx -le 0) { continue }
        $key = $trim.Substring(0, $idx).Trim()
        $val = $trim.Substring($idx + 1).Trim()
        if ($key -match '^[A-Za-z_][A-Za-z0-9_]*$') {
            $map[$key] = $val
        }
    }
    return $map
}

function Test-ExternalKeyPresent {
    param(
        [string]$Path = '',
        [string]$KeyName = 'DEEPSEEK_API_KEY'
    )
    $map = Get-ExternalSecretEnv -Path $Path
    if ($map.ContainsKey($KeyName)) {
        return (-not [string]::IsNullOrWhiteSpace([string]$map[$KeyName]))
    }
    return $false
}

# ---------------------------------------------------------------------------
# Run config (no secrets)
# ---------------------------------------------------------------------------

function Get-Stage2aRunConfig {
    param([string]$RepoRoot = '')
    if (-not $RepoRoot) { $RepoRoot = Get-Stage2aRepoRoot }
    $rel = ($script:DefaultRunConfigRel -replace '/', [IO.Path]::DirectorySeparatorChar)
    $full = Join-Path $RepoRoot $rel
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        throw "run config not found: $rel"
    }
    return ([System.IO.File]::ReadAllText($full) | ConvertFrom-Json)
}

# ---------------------------------------------------------------------------
# Leak scan — searches for the key VALUE without printing it
# ---------------------------------------------------------------------------

function Test-KeyLeakedInRepo {
    param(
        [Parameter(Mandatory)][string]$KeyValue,
        [string]$RepoRoot = ''
    )
    if (-not $RepoRoot) { $RepoRoot = Get-Stage2aRepoRoot }
    if ([string]::IsNullOrWhiteSpace($KeyValue)) { return $false }

    $git = 'git.exe'
    $gitFull = Get-Command $git -ErrorAction SilentlyContinue
    if ($gitFull) { $git = $gitFull.Source }

    $files = New-Object System.Collections.Generic.List[string]
    try {
        $tracked = & $git -C $RepoRoot ls-files 2>$null
        foreach ($f in $tracked) { $files.Add((Join-Path $RepoRoot $f)) | Out-Null }
    }
    catch { }

    # current working-tree diff (modified/untracked text)
    try {
        $diffNames = & $git -C $RepoRoot diff --name-only HEAD 2>$null
        foreach ($f in $diffNames) {
            $full = Join-Path $RepoRoot $f
            if (-not $files.Contains($full)) { $files.Add($full) | Out-Null }
        }
    }
    catch { }

    # untracked files (working tree) — catches planted leaks
    try {
        $untracked = & $git -C $RepoRoot ls-files --others --exclude-standard 2>$null
        foreach ($f in $untracked) {
            $full = Join-Path $RepoRoot $f
            if (-not $files.Contains($full)) { $files.Add($full) | Out-Null }
        }
    }
    catch { }

    # evidence dir + logs
    $evidenceDir = Join-Path $RepoRoot '06_Research/pilots/v1.6-hermes'
    if (Test-Path -LiteralPath $evidenceDir) {
        foreach ($f in (Get-ChildItem -LiteralPath $evidenceDir -Recurse -File -Include *.md,*.json,*.txt -ErrorAction SilentlyContinue)) {
            if (-not $files.Contains($f.FullName)) { $files.Add($f.FullName) | Out-Null }
        }
    }
    foreach ($f in (Get-ChildItem -LiteralPath $RepoRoot -Recurse -File -Filter *.log -ErrorAction SilentlyContinue)) {
        if (-not $files.Contains($f.FullName)) { $files.Add($f.FullName) | Out-Null }
    }

    $matchCount = 0
    foreach ($f in $files) {
        if (-not (Test-Path -LiteralPath $f -PathType Leaf)) { continue }
        try {
            $bytes = [System.IO.File]::ReadAllBytes($f)
            $size = $bytes.Length
            if ($size -gt (4 * 1024 * 1024)) { continue }   # skip binary/huge
            $text = [System.Text.Encoding]::UTF8.GetString($bytes)
            if ($text.IndexOf($KeyValue, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                $matchCount++
            }
        }
        catch { }
    }
    return ($matchCount -gt 0)
}

# ---------------------------------------------------------------------------
# Preflight — value-safe (never returns the key)
# ---------------------------------------------------------------------------

function Invoke-Stage2aPreflight {
    param(
        [string]$SecretPath = '',
        [string]$RepoRoot = '',
        [string]$RunConfigPath = '',
        [string]$ExpectedModel = ''
    )
    if (-not $RepoRoot) { $RepoRoot = Get-Stage2aRepoRoot }
    if (-not $ExpectedModel) { $ExpectedModel = $script:DefaultModel }

    $checks = New-Object System.Collections.Generic.List[object]
    $fail = 0

    # 1. secret file exists
    $secretExists = Test-ExternalSecretFile -Path $SecretPath
    $fullSecret = Get-ExternalSecretPath -Path $SecretPath
    $c1Status = 'FAIL'
    $c1Detail = "missing: $fullSecret (owner fills it; value never read here)"
    if ($secretExists) {
        $c1Status = 'PASS'
        $c1Detail = 'external secret file present (outside repo)'
    }
    $checks.Add([ordered]@{ name = 'secret_file_exists'; status = $c1Status; detail = $c1Detail }) | Out-Null
    if (-not $secretExists) { $fail++ }

    # 2. DEEPSEEK_API_KEY non-empty (value never printed)
    $keyPresent = $false
    if ($secretExists) {
        try { $keyPresent = Test-ExternalKeyPresent -Path $SecretPath -KeyName 'DEEPSEEK_API_KEY' } catch { $keyPresent = $false }
    }
    $c2Status = 'FAIL'
    $c2Detail = 'DEEPSEEK_API_KEY missing or empty in external secret file'
    if ($keyPresent) {
        $c2Status = 'PASS'
        $c2Detail = 'DEEPSEEK_API_KEY present and non-empty (value hidden)'
    }
    $checks.Add([ordered]@{ name = 'api_key_non_empty'; status = $c2Status; detail = $c2Detail }) | Out-Null
    if (-not $keyPresent) { $fail++ }

    # 3. key not leaked in repo/diff/evidence/logs
    $leak = $false
    if ($keyPresent) {
        $map = Get-ExternalSecretEnv -Path $SecretPath
        $leak = Test-KeyLeakedInRepo -KeyValue ([string]$map['DEEPSEEK_API_KEY']) -RepoRoot $RepoRoot
    }
    $c3Status = 'FAIL'
    $c3Detail = 'KEY VALUE FOUND in tracked files/diff/evidence/logs — hard stop'
    if (-not $leak) {
        $c3Status = 'PASS'
        $c3Detail = 'key value not found in tracked files, diff, evidence, or logs'
    }
    $checks.Add([ordered]@{ name = 'no_key_in_repo_diff_evidence_logs'; status = $c3Status; detail = $c3Detail }) | Out-Null
    if ($leak) { $fail++ }

    # 4. run config: model + caps set
    $cfg = $null
    try { $cfg = Get-Stage2aRunConfig -RepoRoot $RepoRoot } catch { $cfg = $null }
    $modelOk = ($null -ne $cfg -and [string]$cfg.model -eq $ExpectedModel)
    $capOk = ($null -ne $cfg -and [double]$cfg.cap_usd -gt 0 -and [long]$cfg.cap_total_tokens -gt 0 -and [int]$cfg.max_output_tokens -gt 0)
    $c4Status = 'FAIL'
    $c4Detail = 'model/caps not fully configured in stage2a-run-config.json'
    if ($modelOk -and $capOk) {
        $c4Status = 'PASS'
        $c4Detail = "model=$($cfg.model) cap_usd=$($cfg.cap_usd) cap_tokens=$($cfg.cap_total_tokens) max_output_tokens=$($cfg.max_output_tokens)"
    }
    $checks.Add([ordered]@{ name = 'run_config_set'; status = $c4Status; detail = $c4Detail }) | Out-Null
    if (-not ($modelOk -and $capOk)) { $fail++ }

    $ok = ($fail -eq 0)
    $verdict = 'BLOCKED'
    if ($ok) { $verdict = 'READY_FOR_LIVE_RUN' }
    return [ordered]@{
        ok           = $ok
        verdict      = $verdict
        checks       = $checks.ToArray()
        failed_count = $fail
        model        = $ExpectedModel
        secret_path  = $fullSecret
    }
}

$script:SecretLoaderLoaded = $true
