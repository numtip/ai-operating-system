<#
.SYNOPSIS
  Deterministic validation for the Hermes local-memory pilot (no Hermes, no network).
  Proves: manifest pins 1-3 sources, every source exists with matching SHA-256,
  allowlist target is 03_Memory/inbox, note (if produced) has all required fields +
  status REVIEW_REQUIRED + source refs + no secrets. Optionally validates the pilot
  evidence file when present.
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File prompt-compiler/tests/run-tests-hermes-memory-pilot.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = [string](Resolve-Path (Join-Path $PSScriptRoot '../..'))

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

function Read-JsonFile {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "missing file: $Path" }
    return ([System.IO.File]::ReadAllText($Path) | ConvertFrom-Json)
}

$manifestPath = Join-Path $Root 'scripts/hermes-memory-pilot-manifest.json'
$manifest = Read-JsonFile $manifestPath

# --- 1. manifest contract ---
Assert-True '1a.manifest_schema_version' ($manifest.schema_version -eq '1.0') "v=$($manifest.schema_version)"
$srcCount = @($manifest.source_files).Count
Assert-True '1b.manifest_source_count_1_to_3' ($srcCount -ge 1 -and $srcCount -le 3) "count=$srcCount"
Assert-True '1c.manifest_allowlist_inbox' ([string]$manifest.output.allowlist_dir -eq '03_Memory/inbox') "allowlist=$($manifest.output.allowlist_dir)"
Assert-True '1d.manifest_note_status_review_required' ([string]$manifest.output.note_status -eq 'REVIEW_REQUIRED') "status=$($manifest.output.note_status)"
foreach ($f in @('title','date','status','verified_facts','open_decisions','next_actions','sources')) {
    Assert-True ("1e.required_field_{0}" -f $f) (@($manifest.output.note_required_fields) -contains $f)
}

# --- 2. source integrity (paths exist + SHA-256 match) ---
$allHashesOk = $true
foreach ($s in @($manifest.source_files)) {
    $full = Join-Path $Root $s.path
    $exists = Test-Path -LiteralPath $full -PathType Leaf
    Assert-True ("2a.source_exists_{0}" -f ($s.path -replace '/','_')) $exists "path=$($s.path)"
    if ($exists) {
        $h = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash.ToLowerInvariant()
        $match = ($h -eq $s.sha256)
        Assert-True ("2b.source_hash_{0}" -f ($s.path -replace '/','_')) $match "expected=$($s.sha256) actual=$h"
        if (-not $match) { $allHashesOk = $false }
    }
    else { $allHashesOk = $false }
}
Assert-True '2c.all_source_hashes_match' $allHashesOk

# --- 3. pilot script exists and is fail-closed ---
$scriptPath = Join-Path $Root 'scripts/run-hermes-memory-pilot.ps1'
Assert-True '3a.pilot_script_exists' (Test-Path -LiteralPath $scriptPath -PathType Leaf)
if (Test-Path -LiteralPath $scriptPath) {
    $scriptText = [System.IO.File]::ReadAllText($scriptPath)
    Assert-True '3b.script_allowlist_inbox' ($scriptText -match '03_Memory/inbox')
    Assert-True '3c.script_fail_closed_hermes_missing' ($scriptText -match 'HERMES_CLI_NOT_FOUND')
    Assert-True '3d.script_no_install' ($scriptText -match 'never re-installs' -or $scriptText -match 'install is out of scope')
    Assert-True '3e.script_max_1_retry' ($scriptText -match 'MaxAttempts' -and $scriptText -match 'at most 1 retry')
    Assert-True '3f.script_rollback_on_fail' ($scriptText -match 'Remove-DraftOutput' -or $scriptText -match 'Remove-Draft')
}

# --- 4. note (if produced by a live run) validates ---
$notePath = Join-Path $Root '03_Memory/inbox/GOFFICE-OPERATIONAL-MEMORY-DRAFT.md'
if (Test-Path -LiteralPath $notePath -PathType Leaf) {
    $note = [System.IO.File]::ReadAllText($notePath)
    Assert-True '4a.note_has_title' ($note -match '(?im)^title:')
    Assert-True '4b.note_has_date' ($note -match '(?im)^date:')
    Assert-True '4c.note_status_review_required' ($note -match 'REVIEW_REQUIRED')
    Assert-True '4d.note_verified_facts' ($note -match '(?im)^verified_facts:')
    Assert-True '4e.note_open_decisions' ($note -match '(?im)^open_decisions:')
    Assert-True '4f.note_next_actions' ($note -match '(?im)^next_actions:')
    Assert-True '4g.note_sources' ($note -match '(?im)^sources:')
    foreach ($s in @($manifest.source_files)) {
        Assert-True ("4h.note_refs_{0}" -f ($s.path -replace '/','_')) ($note -match [regex]::Escape($s.path))
        Assert-True ("4i.note_hash_{0}" -f ($s.path -replace '/','_')) ($note -match [regex]::Escape($s.sha256))
    }
    $secretPatterns = @('sk-[a-zA-Z0-9]{10,}','Bearer\s+[a-zA-Z0-9._\-]{10,}','DEEPSEEK_API_KEY\s*[=:]\s*\S+','-----BEGIN [A-Z ]*PRIVATE KEY-----')
    foreach ($p in $secretPatterns) {
        Assert-True ("4j.note_no_secret_{0}" -f $p) (-not ($note -match $p)) "pattern=$p"
    }
}
else {
    Write-Host 'SKIP  4a-4j note validation (no draft note present yet)'
}

# --- 5. evidence file (if present) is sanitized ---
$evPath = Join-Path $Root '06_Research/pilots/v1.6-hermes/HERMES-MEMORY-PILOT-EVIDENCE.json'
if (Test-Path -LiteralPath $evPath -PathType Leaf) {
    $ev = Read-JsonFile $evPath
    Assert-True '5a.evidence_verdict_in_enum' (@('HERMES_OBSIDIAN_LOCAL_MEMORY_PASS','BLOCKED') -contains [string]$ev.verdict) "verdict=$($ev.verdict)"
    Assert-True '5b.evidence_allowlist_inbox' ([string]$ev.allowlist_dir -eq '03_Memory/inbox')
    $evText = [System.IO.File]::ReadAllText($evPath)
    Assert-True '5c.evidence_no_secrets' (-not ($evText -match 'sk-[a-zA-Z0-9]{10,}|DEEPSEEK_API_KEY\s*[=:]\s*\S+|Bearer\s+[a-zA-Z0-9._\-]{10,}'))
}
else {
    Write-Host 'SKIP  5a-5c evidence validation (no pilot evidence file yet)'
}

Write-Host ''
Write-Host ("HERMES-MEMORY-PILOT SUMMARY passed={0} failed={1}" -f $passed, $failed)
if ($failed -gt 0) { exit 1 } else { exit 0 }
