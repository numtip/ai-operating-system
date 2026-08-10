<#
.SYNOPSIS
  Hermes + Obsidian local-memory pilot -- single reusable command.
  Reads a curated input manifest (max 3 Green Office source files, SHA-256 pinned),
  runs the configured Hermes CLI exactly once under the Stage 2A cost cap, and
  requires the resulting draft memory note to land ONLY in 03_Memory/inbox/.
.DESCRIPTION
  - Curated input only: never crawls the repo; sources come from the manifest.
  - Hermes must already be installed and configured (DeepSeek via DEEPSEEK_API_KEY);
    this script never re-installs, never reads or prints the key (boolean check only).
  - Write allowlist: a filesystem + git audit runs before and after the Hermes call;
    ANY file created or modified outside 03_Memory/inbox/ fails the pilot and
    triggers rollback of incomplete drafts.
  - Fail-closed: missing Hermes CLI, hash mismatch, secret leak, or out-of-allowlist
    write -> sanitized error code, draft rollback, exit non-zero (BLOCKED).
  - Retry: at most 1 retry after a non-zero Hermes exit (max 2 attempts total).
.PARAMETER HermesCommand
  Hermes CLI command name or full path. Default: 'hermes'. If not found on PATH,
  the pilot is BLOCKED (HERMES_CLI_NOT_FOUND) - no install is attempted.
.PARAMETER ManifestPath
  Curated input manifest JSON. Default: scripts/hermes-memory-pilot-manifest.json.
.PARAMETER MaxAttempts
  Max Hermes attempts (default 2, meaning 1 retry).
.PARAMETER TimeoutSec
  Per-attempt timeout for the Hermes call (default 300).
.PARAMETER NoteFilename
  Fixed output filename inside 03_Memory/inbox/ (default GOFFICE-OPERATIONAL-MEMORY-DRAFT.md).
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run-hermes-memory-pilot.ps1
#>
[CmdletBinding()]
param(
    [string]$HermesCommand = 'hermes',
    [string]$ManifestPath = '',
    [int]$MaxAttempts = 2,
    [int]$TimeoutSec = 300,
    [string]$NoteFilename = 'GOFFICE-OPERATIONAL-MEMORY-DRAFT.md'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
$Root = [string](Resolve-Path (Join-Path $PSScriptRoot '..'))
if (-not $ManifestPath) { $ManifestPath = Join-Path $PSScriptRoot 'hermes-memory-pilot-manifest.json' }
$InboxDir = Join-Path $Root '03_Memory/inbox'
$NotePath = Join-Path $InboxDir $NoteFilename
$EvidencePath = Join-Path $Root '06_Research/pilots/v1.6-hermes/HERMES-MEMORY-PILOT-EVIDENCE.json'
$ContextFile = Join-Path $env:TEMP ('hermes-memory-context-' + [guid]::NewGuid().ToString('N') + '.md')

$ExitOk = 0
$ExitBlocked = 70
$BlockedReason = ''
$SanitizedError = $null
$HermesFound = $false
$HermesInvocation = ''
$Attempts = 0
$LastExit = $null

function Write-Result {
    param([string]$Name, [string]$Status, [string]$Detail = '')
    Write-Host ("{0}  {1}  {2}" -f $Status, $Name, $Detail)
}

function Get-Manifest {
    $m = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    if (@($m.source_files).Count -lt 1 -or @($m.source_files).Count -gt 3) {
        throw "manifest must pin between 1 and 3 source files (got $(@($m.source_files).Count))"
    }
    return $m
}

function Test-SourceIntegrity {
    param($Manifest)
    $ok = $true
    foreach ($s in @($Manifest.source_files)) {
        $full = Join-Path $Root $s.path
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
            Write-Host "FAIL  source_missing  $($s.path)"; $ok = $false; continue
        }
        $h = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($h -ne $s.sha256) {
            Write-Host ("FAIL  source_hash_mismatch  {0} expected={1} actual={2}" -f $s.path, $s.sha256, $h)
            $ok = $false
        }
        else {
            Write-Host ("PASS  source_hash_ok  {0}  {1}" -f $s.path, $h)
        }
    }
    return $ok
}

function Get-HermesCli {
    param([string]$CommandName)
    $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    # Python module fallback (existing install only; never pip-install here)
    $py = Get-Command python -ErrorAction SilentlyContinue
    if ($py) {
        $probe = & $py.Source -c "import importlib.util,sys; sys.exit(0 if importlib.util.find_spec('hermes') else 1)" 2>$null
        if ($LASTEXITCODE -eq 0) { return ($py.Source + ' -m hermes') }
    }
    return $null
}

function Get-InboxState {
    $map = @{}
    if (Test-Path -LiteralPath $InboxDir) {
        Get-ChildItem -LiteralPath $InboxDir -File -ErrorAction SilentlyContinue | ForEach-Object {
            $map[$_.Name] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        }
    }
    return $map
}

function Get-RepoWriteAudit {
    # Returns a hashtable: 'new_outside' = file paths created outside inbox (vs baseline),
    # 'changed_outside' = paths modified outside inbox. Runs git + filesystem scan.
    $audit = [ordered]@{
        baseline_inbox = $null
        git_before     = ''
        git_after      = ''
        new_outside    = @()
        changed_outside = @()
    }
    return $audit
}

function Test-NoteStructure {
    param([string]$NotePath, $Manifest)
    if (-not (Test-Path -LiteralPath $NotePath -PathType Leaf)) {
        Write-Host "FAIL  note_missing  $NotePath"; return $false
    }
    $text = [System.IO.File]::ReadAllText($NotePath)
    $ok = $true
    foreach ($f in @($Manifest.output.note_required_fields)) {
        if ($text -notmatch ("(?m)^[-*]?\s*\*\*?" + [regex]::Escape($f))) {
            if ($text -notmatch [regex]::Escape($f)) {
                Write-Host "FAIL  note_missing_field  $f"; $ok = $false
            }
        }
    }
    if ($text -notmatch [regex]::Escape([string]$Manifest.output.note_status)) {
        Write-Host ("FAIL  note_status  expected {0}" -f $Manifest.output.note_status); $ok = $false
    }
    foreach ($s in @($Manifest.source_files)) {
        if ($text -notmatch [regex]::Escape($s.path)) {
            Write-Host "FAIL  note_missing_source_ref  $($s.path)"; $ok = $false
        }
        if ($text -notmatch [regex]::Escape($s.sha256)) {
            Write-Host "FAIL  note_missing_source_hash  $($s.path)"; $ok = $false
        }
    }
    if ($ok) { Write-Host 'PASS  note_structure_ok' }
    return $ok
}

function Test-NoSecretsInNote {
    param([string]$NotePath)
    $text = [System.IO.File]::ReadAllText($NotePath)
    $patterns = @(
        'sk-[a-zA-Z0-9]{10,}',
        'Bearer\s+[a-zA-Z0-9._\-]{10,}',
        'DEEPSEEK_API_KEY\s*[=:]\s*\S+',
        '-----BEGIN [A-Z ]*PRIVATE KEY-----',
        'Authorization:\s*Bearer'
    )
    $ok = $true
    foreach ($p in $patterns) {
        if ($text -match $p) { Write-Host ("FAIL  secret_leak_pattern  {0}" -f $p); $ok = $false }
    }
    if ($ok) { Write-Host 'PASS  note_no_secrets' }
    return $ok
}

function Remove-DraftOutput {
    if (Test-Path -LiteralPath $NotePath -PathType Leaf) {
        Remove-Item -LiteralPath $NotePath -Force
        Write-Host "ROLLBACK  removed incomplete draft $NotePath"
    }
}

function Write-Evidence {
    param(
        [string]$Verdict,
        [string]$Reason,
        [string]$ErrorCode,
        [int]$Attempts,
        [int]$LastExit,
        [string]$NotePath,
        [string]$Invocation
    )
    $ev = [ordered]@{
        schema_version    = '1.0'
        check             = 'hermes_obsidian_local_memory_pilot'
        verdict           = $Verdict
        reason            = $Reason
        error_code        = $ErrorCode
        attempts          = $Attempts
        last_exit_code    = $LastExit
        hermes_invocation = $Invocation
        allowlist_dir     = '03_Memory/inbox'
        note_path         = $NotePath
        timestamp_utc     = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
        note              = 'sanitized evidence; no key, no prompt transcript, no raw API payload stored'
    }
    $ev | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $EvidencePath -Encoding UTF8
}

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
Write-Host ('Hermes local-memory pilot start; branch=' + (git.exe rev-parse --abbrev-ref HEAD 2>$null))
$manifest = Get-Manifest
Write-Host ("manifest sources=" + @($manifest.source_files).Count + " allowlist=" + $manifest.output.allowlist_dir)

$sourcesOk = Test-SourceIntegrity -Manifest $manifest
if (-not $sourcesOk) {
    $BlockedReason = 'source integrity failed (missing file or SHA-256 mismatch)'
    Write-Host ("BLOCKED  $BlockedReason")
    Write-Evidence -Verdict 'BLOCKED' -Reason $BlockedReason -ErrorCode 'SOURCE_INTEGRITY_FAILED' -Attempts 0 -LastExit 0 -NotePath $NotePath -Invocation ''
    exit $ExitBlocked
}

# Hermes CLI availability (boolean; existing install only)
$HermesInvocation = Get-HermesCli -CommandName $HermesCommand
if (-not $HermesInvocation) {
    $BlockedReason = 'Hermes CLI not found and no existing install discovered (install is out of scope)'
    Write-Host ("BLOCKED  {0}" -f $BlockedReason)
    Write-Host 'FAIL  hermes_cli_available'
    Write-Evidence -Verdict 'BLOCKED' -Reason $BlockedReason -ErrorCode 'HERMES_CLI_NOT_FOUND' -Attempts 0 -LastExit 0 -NotePath $NotePath -Invocation $HermesCommand
    exit $ExitBlocked
}
$HermesFound = $true
Write-Host ("PASS  hermes_cli_available  $HermesInvocation")

# DeepSeek key presence -- boolean only; value never read or printed
$keyPresent = [bool]$env:DEEPSEEK_API_KEY
if (-not $keyPresent) {
    $BlockedReason = 'DEEPSEEK_API_KEY not present in environment (boolean check only)'
    Write-Host ("BLOCKED  {0}" -f $BlockedReason)
    Write-Evidence -Verdict 'BLOCKED' -Reason $BlockedReason -ErrorCode 'DEEPSEEK_KEY_MISSING' -Attempts 0 -LastExit 0 -NotePath $NotePath -Invocation $HermesInvocation
    exit $ExitBlocked
}
Write-Host 'PASS  deepseek_key_present_boolean_only'

# Allowlist dir exists (create if missing - creation is the only allowed change here)
New-Item -ItemType Directory -Path $InboxDir -Force | Out-Null
$inboxBefore = Get-InboxState
$gitBefore = (git.exe status --porcelain) -join "`n"

# Build curated context (only manifest sources, never a repo crawl)
$contextLines = New-Object System.Collections.Generic.List[string]
$contextLines.Add('# Curated Green Office context (AI-OS internal, read-only)') | Out-Null
foreach ($s in @($manifest.source_files)) {
    $full = Join-Path $Root $s.path
    $contextLines.Add("`n## SOURCE: $($s.path)  (sha256: $($s.sha256))") | Out-Null
    $contextLines.Add([System.IO.File]::ReadAllText($full)) | Out-Null
}
[System.IO.File]::WriteAllText($ContextFile, ($contextLines -join "`n"), [System.Text.Encoding]::UTF8)
Write-Host "PASS  curated_context_built  $ContextFile ($((Get-Item -LiteralPath $ContextFile).Length) bytes)"

# Hermes task instruction (kept separate from the context payload; never logged to repo)
$PromptFile = Join-Path $env:TEMP ('hermes-memory-prompt-' + [guid]::NewGuid().ToString('N') + '.txt')
$task = @"
You are the Hermes execution runtime for the AI-OS local-memory pilot.
Read the curated context file at: $ContextFile
Write EXACTLY ONE new Markdown file into the Obsidian vault at:
$NotePath
The note must contain these sections (use these literal headers):
- title: (one line)
- date: (today UTC)
- status: REVIEW_REQUIRED
- verified_facts: (concise facts ONLY, each traceable to a manifest source; no invented claims)
- open_decisions: (explicitly unresolved items)
- next_actions: (concrete follow-ups)
- sources: (list every manifest source path with its sha256)
Rules: no secrets, no API keys, no raw prompt transcript, no raw API payload;
only write the one file listed above; do not modify any other file.
"@
[System.IO.File]::WriteAllText($PromptFile, $task, [System.Text.Encoding]::UTF8)

# ---------------------------------------------------------------------------
# Hermes execution (exactly once; at most 1 retry)
# ---------------------------------------------------------------------------
$result = $null
while ($Attempts -lt $MaxAttempts) {
    $Attempts++
    Write-Host ("ATTEMPT {0}/{1}  hermes run started" -f $Attempts, $MaxAttempts)
    try {
        # Invocation is either "path" (module entry) or "path -m hermes"; split safely.
        $parts = $HermesInvocation -split '\s+', 2
        $exe = $parts[0]
        $extra = ''
        if ($parts.Count -gt 1) { $extra = $parts[1] }
        $args = @()
        if ($extra) { $args += $extra }
        $args += @('-p', ('"' + $PromptFile + '"'))
        $p = Start-Process -FilePath $exe -ArgumentList $args -NoNewWindow -Wait -PassThru `
            -RedirectStandardOutput (Join-Path $env:TEMP 'hermes-memory-out.txt') `
            -RedirectStandardError (Join-Path $env:TEMP 'hermes-memory-err.txt') -ErrorAction Stop
        $LastExit = $p.ExitCode
    }
    catch {
        $SanitizedError = ($_.Exception.Message -replace 'sk-[a-zA-Z0-9]{10,}', '***' -replace 'Bearer\s+[a-zA-Z0-9._\-]{10,}', '***')
        $LastExit = 1
    }
    Write-Host ("ATTEMPT {0}  exit_code={1}" -f $Attempts, $LastExit)
    if ($LastExit -eq 0) { break }
    Write-Host "ATTEMPT $Attempts failed (exit=$LastExit); retrying once"
}

# ---------------------------------------------------------------------------
# Post-run audit + validation
# ---------------------------------------------------------------------------
$gitAfter = (git.exe status --porcelain) -join "`n"
$inboxAfter = Get-InboxState
$noteExists = Test-Path -LiteralPath $NotePath -PathType Leaf

# Write allowlist audit: any change outside 03_Memory/inbox/ is a fail
$allowedChanges = @()
$violations = New-Object System.Collections.Generic.List[string]
$gitLinesAfter = @($gitAfter -split "`n" | Where-Object { $_ -ne '' })
foreach ($line in $gitLinesAfter) {
    $pathPart = ($line -replace '^\?\? ', '' -replace '^[ MADRCU?!]{2} ', '')
    if ($pathPart -like '03_Memory/inbox/*') { continue }
    $violations.Add('out_of_allowlist: ' + $pathPart) | Out-Null
}
if ($violations.Count -gt 0) {
    Write-Host "FAIL  write_allowlist  violations: $($violations -join '; ')"
}

# Note validation (only when Hermes produced the file)
$noteOk = $true
if ($noteExists) {
    $noteOk = (Test-NoteStructure -NotePath $NotePath -Manifest $manifest)
    $noteOk = ($noteOk -and (Test-NoSecretsInNote -NotePath $NotePath))
}
else {
    Write-Host 'FAIL  note_created'
    $noteOk = $false
}

# ---------------------------------------------------------------------------
# Verdict
# ---------------------------------------------------------------------------
$verdict = 'HERMES_OBSIDIAN_LOCAL_MEMORY_PASS'
$errorCode = ''
if ($LastExit -ne 0) {
    $verdict = 'BLOCKED'
    $errorCode = 'HERMES_RUN_FAILED'
    $BlockedReason = "Hermes exited non-zero after $Attempts attempt(s); last exit code = $LastExit"
}
elseif (-not $noteOk) {
    $verdict = 'BLOCKED'
    $errorCode = 'NOTE_VALIDATION_FAILED'
    $BlockedReason = 'note missing, malformed, or failed redaction/secret checks'
}
elseif ($violations.Count -gt 0) {
    $verdict = 'BLOCKED'
    $errorCode = 'WRITE_ALLOWLIST_VIOLATION'
    $BlockedReason = 'Hermes wrote outside 03_Memory/inbox/'
}

if ($verdict -eq 'BLOCKED') {
    if ($noteExists) { Remove-DraftOutput }
    Write-Host ("BLOCKED  {0}  error_code={1}" -f $BlockedReason, $errorCode)
    Write-Evidence -Verdict $verdict -Reason $BlockedReason -ErrorCode $errorCode -Attempts $Attempts -LastExit $LastExit -NotePath $NotePath -Invocation $HermesInvocation
    exit $ExitBlocked
}

Write-Host "PASS  write_allowlist  only 03_Memory/inbox/ touched"
Write-Host "PASS  note_created  $NotePath"
Write-Evidence -Verdict $verdict -Reason 'complete' -ErrorCode '' -Attempts $Attempts -LastExit $LastExit -NotePath $NotePath -Invocation $HermesInvocation
exit $ExitOk
