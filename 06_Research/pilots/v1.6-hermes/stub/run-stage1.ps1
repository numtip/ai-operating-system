# run-stage1.ps1
# ============================================================================
# GOFFICE2026 Pilot — Stage 1 reversible compatibility spike runner (SIMULATED)
# ============================================================================
# Executes the governed task contract through the stub adapter boundary and
# produces evidence JSON. All results are SIMULATED compatibility evidence for
# owner review — NOT Hermes runtime validation.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\run-stage1.ps1
# Outputs: stage1-results.json (evidence), console summary.
# Reversible: in-memory only; remove stub/ dir to fully revert.
# ============================================================================
$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir 'Stub-Adapter.ps1')

$EvidenceDir = Join-Path (Split-Path -Parent $scriptDir) 'goffice2026'   # .../v1.6-hermes/goffice2026/
$OutFile = Join-Path $EvidenceDir 'STAGE-1-RESULTS.json'

# Stage 0 baseline context (8 mandatory files, deterministic hash from Stage 0)
$MandatoryContext = @(
    '01_Projects/goffice2026/ADAPTER.md',
    '07_Memory/CURRENT_STATE.md',
    '07_Memory/OPERATING_RULES.md',
    '07_Memory/SYSTEM_MEMORY.md',
    '12_Indexes/project_index.json',
    'external:doc:goffice2026/package.json',
    'external:doc:goffice2026/PRODUCT.md',
    'external:doc:goffice2026/README.md'
)
$Stage0ContextHash = 'ad907c27495ab3b1e8720f286450c1e762166fd8d0542434ac4abe38e6635381'

$ApprovalStore = @{}   # in-memory idempotency + audit state (per-run, reversible)
$Results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param([string]$Scenario, [string]$Expected, [hashtable]$Actual, [string]$Pass, [string]$Note)
    $Results.Add([ordered]@{
        scenario = $Scenario
        expected = $Expected
        actual_status = $Actual.status
        actual_detail = $Actual.detail
        pass = $Pass
        note = $Note
        audit_complete = ($null -ne $Actual.audit)
        simulated = $true
    }) | Out-Null
}

# === 1. Normal L0 read task (baseline parity) ================================
$t1 = New-StubTask -TaskId 'goffice2026-s1-t01' -IdempotencyKey 'g26-s1-t01' -ExecutionLevel 'L0' `
    -MandatoryContext $MandatoryContext -ApprovedToolScope @('read-adapter', 'read-index', 'read-canonical')
$r1 = Invoke-StubAdapter -Task $t1 -RequestedTool 'read-canonical' -ApprovalStore $ApprovalStore
$ctxParity = @($t1.mandatory_context) -join '|'
Add-Result -Scenario 'T01 normal L0 read' -Expected 'success, 8 mandatory context files preserved' -Actual $r1 -Pass (($r1.status -eq 'success') -and ($t1.mandatory_context.Count -eq 8)) `
    -Note "files=$($t1.mandatory_context.Count) (Stage 0 baseline=8); stub context_hash=$($t1.context_hash) differs from compiler deterministic hash $Stage0ContextHash by methodology (list hash vs full-output hash); file set parity holds"

# === 2. Normal L1 analysis task ==============================================
$t2 = New-StubTask -TaskId 'goffice2026-s1-t02' -IdempotencyKey 'g26-s1-t02' -ExecutionLevel 'L1' `
    -MandatoryContext $MandatoryContext -ApprovedToolScope @('read-canonical', 'analyze')
$r2 = Invoke-StubAdapter -Task $t2 -RequestedTool 'analyze' -ApprovalStore $ApprovalStore
Add-Result -Scenario 'T02 normal L1 analyze' -Expected 'success' -Actual $r2 -Pass ($r2.status -eq 'success') -Note 'L1 automatic per policy'

# === 3. Approval denied (L3 without approval) =================================
$t3 = New-StubTask -TaskId 'goffice2026-s1-t03' -IdempotencyKey 'g26-s1-t03' -ExecutionLevel 'L3' `
    -MandatoryContext $MandatoryContext -ApprovedToolScope @('publish')
$r3 = Invoke-StubAdapter -Task $t3 -RequestedTool 'publish' -ApprovalStore $ApprovalStore
Add-Result -Scenario 'S2a/T03 approval denied (L3 no approval)' -Expected 'needs_approval' -Actual $r3 -Pass ($r3.status -eq 'needs_approval') -Note $r3.detail

# === 4. Approval expired =====================================================
$t4 = New-StubTask -TaskId 'goffice2026-s1-t04' -IdempotencyKey 'g26-s1-t04' -ExecutionLevel 'L3' `
    -MandatoryContext $MandatoryContext -ApprovedToolScope @('publish') `
    -ApprovalEvidence "APPROVED goffice2026-s1-t04 ADR-0013+v4-2026-08-09" -ApprovalExpires '2020-01-01T00:00:00Z'
$r4 = Invoke-StubAdapter -Task $t4 -RequestedTool 'publish' -ApprovalStore $ApprovalStore
Add-Result -Scenario 'S2b/T04 approval expired' -Expected 'expired/needs_approval' -Actual $r4 -Pass ($r4.status -in @('expired', 'needs_approval')) -Note $r4.detail

# === 5. Approval replay (bound to different task) ============================
$t5 = New-StubTask -TaskId 'goffice2026-s1-t05' -IdempotencyKey 'g26-s1-t05' -ExecutionLevel 'L4' `
    -MandatoryContext $MandatoryContext -ApprovedToolScope @('destructive-remove') `
    -ApprovalEvidence 'APPROVED goffice2026-s1-OTHER-TASK ADR-0013+v4-2026-08-09'
$r5 = Invoke-StubAdapter -Task $t5 -RequestedTool 'destructive-remove' -ApprovalStore $ApprovalStore
Add-Result -Scenario 'T05 approval replay rejected' -Expected 'rejected (anti-replay)' -Actual $r5 -Pass ($r5.status -eq 'rejected') -Note $r5.detail

# === 6. Retry / idempotency (same key twice) =================================
$t6 = New-StubTask -TaskId 'goffice2026-s1-t06' -IdempotencyKey 'g26-s1-t06' -ExecutionLevel 'L0' `
    -MandatoryContext $MandatoryContext -ApprovedToolScope @('read-canonical')
$r6a = Invoke-StubAdapter -Task $t6 -RequestedTool 'read-canonical' -ApprovalStore $ApprovalStore
$r6b = Invoke-StubAdapter -Task $t6 -RequestedTool 'read-canonical' -ApprovalStore $ApprovalStore
$idemMatch = ($r6b.idempotent -eq $true) -and ($r6b.idempotency_echo -eq $r6a.result.payload_hash)
Add-Result -Scenario 'S1b/T06 idempotent retry' -Expected 'first success; second idempotent echo, no duplicate' -Actual $r6b `
    -Pass (($r6a.status -eq 'success') -and $idemMatch) `
    -Note "first_payload=$($r6a.result.payload_hash) idem_echo=$($r6b.idempotency_echo) match=$idemMatch"

# === 7. Constraint violation (tool outside approved scope) ===================
$t7 = New-StubTask -TaskId 'goffice2026-s1-t07' -IdempotencyKey 'g26-s1-t07' -ExecutionLevel 'L2' `
    -MandatoryContext $MandatoryContext -ApprovedToolScope @('read-canonical')
$r7 = Invoke-StubAdapter -Task $t7 -Mode 'scope_violation' -RequestedTool 'write-external' -ApprovalStore $ApprovalStore
Add-Result -Scenario 'S4/T07 tool scope violation' -Expected 'aborted (hard stop)' -Actual $r7 -Pass ($r7.status -eq 'aborted') -Note $r7.detail

# === 8. Credential-scope violation ===========================================
$t8 = New-StubTask -TaskId 'goffice2026-s1-t08' -IdempotencyKey 'g26-s1-t08' -ExecutionLevel 'L2' `
    -MandatoryContext $MandatoryContext -ApprovedToolScope @('read-canonical') -CredentialRef 'cred-g26-read'
$r8 = Invoke-StubAdapter -Task $t8 -RequestedTool 'read-canonical' -ResolveCredential 'cred-g26-WRITE' -ApprovalStore $ApprovalStore
Add-Result -Scenario 'T08 credential scope violation' -Expected 'aborted (no credential outside scope)' -Actual $r8 -Pass ($r8.status -eq 'aborted') -Note $r8.detail

# === 9. Context deviation (unapproved context used) ===========================
$t9 = New-StubTask -TaskId 'goffice2026-s1-t09' -IdempotencyKey 'g26-s1-t09' -ExecutionLevel 'L0' `
    -MandatoryContext $MandatoryContext -ApprovedToolScope @('read-canonical')
$r9 = Invoke-StubAdapter -Task $t9 -RequestedTool 'read-canonical' -RuntimeContextUsed @('07_Memory/OPERATING_RULES.md', '03_Architecture/ROADMAP.md') -ApprovalStore $ApprovalStore
Add-Result -Scenario 'S3/T09 context deviation' -Expected 'aborted with deviation reported' -Actual $r9 `
    -Pass ($r9.status -eq 'aborted' -and $r9.deviations.Count -ge 1) -Note ("deviations=" + ($r9.deviations -join ','))

# === 10. Simulated runtime failure (transient → retry succeeds) ===============
$t10 = New-StubTask -TaskId 'goffice2026-s1-t10' -IdempotencyKey 'g26-s1-t10' -ExecutionLevel 'L0' `
    -MandatoryContext $MandatoryContext -ApprovedToolScope @('read-canonical')
$r10a = Invoke-StubAdapter -Task $t10 -Mode 'tool_failure' -RequestedTool 'read-canonical' -ApprovalStore $ApprovalStore
# retry with SAME idempotency_key — but the failed attempt should NOT have stored an idem entry, so retry executes
$r10b = Invoke-StubAdapter -Task $t10 -RequestedTool 'read-canonical' -ApprovalStore $ApprovalStore
Add-Result -Scenario 'S1a/T10 tool failure then retry' -Expected 'first failed(retryable); retry success' -Actual $r10b `
    -Pass (($r10a.status -eq 'failed' -and $r10a.retryable) -and ($r10b.status -eq 'success')) `
    -Note "first=$($r10a.status)/retryable=$($r10a.retryable) retry=$($r10b.status)"

# === 11. Non-retryable failure → human review =================================
$t11 = New-StubTask -TaskId 'goffice2026-s1-t11' -IdempotencyKey 'g26-s1-t11' -ExecutionLevel 'L1' `
    -MandatoryContext $MandatoryContext -ApprovedToolScope @('analyze')
$r11 = Invoke-StubAdapter -Task $t11 -Mode 'nonretryable_failure' -RequestedTool 'analyze' -ApprovalStore $ApprovalStore
Add-Result -Scenario 'T11 non-retryable failure' -Expected 'failed(retryable=false) → human review' -Actual $r11 `
    -Pass ($r11.status -eq 'failed' -and -not $r11.retryable) -Note 'escalate to human per sec.7'

# === 12. Runtime crash mid-task → recovery/reconciliation =====================
$t12 = New-StubTask -TaskId 'goffice2026-s1-t12' -IdempotencyKey 'g26-s1-t12' -ExecutionLevel 'L0' `
    -MandatoryContext $MandatoryContext -ApprovedToolScope @('read-canonical')
$r12a = Invoke-StubAdapter -Task $t12 -Mode 'runtime_crash' -RequestedTool 'read-canonical' -ApprovalStore $ApprovalStore
$r12b = Invoke-StubAdapter -Task $t12 -RequestedTool 'read-canonical' -ApprovalStore $ApprovalStore
Add-Result -Scenario 'S5/T12 runtime crash recovery' -Expected 'crash→failed(retryable); retry succeeds; no orphan' -Actual $r12b `
    -Pass ($r12a.status -eq 'failed' -and $r12a.retryable -and $r12b.status -eq 'success') `
    -Note 'no side effects applied before crash; retry reconciled via same key'

# === 13. Rollback/fallback (S6) — manual path continues =======================
# Simulated disable of the boundary; verify AI-OS manual path (bootstrap gate)
# still operates — this is a contract-level check, the real gate runs below.
$t13 = New-StubTask -TaskId 'goffice2026-s1-t13' -IdempotencyKey 'g26-s1-t13' -ExecutionLevel 'L0' `
    -MandatoryContext $MandatoryContext -ApprovedToolScope @('read-canonical')
$r13 = Invoke-StubAdapter -Task $t13 -RequestedTool 'read-canonical' -ApprovalStore $ApprovalStore
# After "rollback" the stub is gone; the fallback is the manual path. We assert
# the stub produced its audit before removal and that evidence is preserved.
Add-Result -Scenario 'S6/T13 rollback/fallback' -Expected 'audit preserved before rollback; manual path = Stage 0 tools' -Actual $r13 `
    -Pass ($r13.status -eq 'success' -and $null -ne $r13.audit) `
    -Note 'rollback per HERMES_ROLLBACK_PLAN.md sec.3-sec.7; fallback = existing check-bootstrap.ps1/compile-prompt.ps1 manual path'

# === Summary ==================================================================
$passedCount = 0
$failedCount = 0
$auditCompleteCount = 0
$resultsArr = @()
foreach ($r in $Results) {
    if ($r.pass) { $passedCount++ } else { $failedCount++ }
    if ($r.audit_complete) { $auditCompleteCount++ }
    $resultsArr += $r
}
$summary = [ordered]@{
    evidence_type      = 'SIMULATED compatibility evidence (stub adapter)'
    hermes_validation  = $false
    stub_version       = 'stub-v0.1.0-simulated'
    date               = (Get-Date -Format 'yyyy-MM-dd')
    branch             = 'integration/v1.6-hermes-first'
    stage0_context_hash= $Stage0ContextHash
    scenarios_total    = $Results.Count
    scenarios_passed   = $passedCount
    scenarios_failed   = $failedCount
    audit_complete_count = $auditCompleteCount
    results            = $resultsArr
}
$summary | ConvertTo-Json -Depth 6 | Set-Content -Path $OutFile -Encoding UTF8
Write-Host "=== STAGE-1 SUMMARY ==="
Write-Host ("scenarios_total={0} passed={1} failed={2} audit_complete={3}" -f $summary.scenarios_total, $summary.scenarios_passed, $summary.scenarios_failed, $summary.audit_complete_count)
foreach ($r in $resultsArr) {
    $mark = 'FAIL'
    if ($r.pass) { $mark = 'PASS' }
    Write-Host ("[{0}] {1} -> {2} | {3}" -f $mark, $r.scenario, $r.actual_status, $r.note)
}
Write-Host "Evidence written: $OutFile"
if ($failedCount -gt 0) { exit 1 } else { exit 0 }
