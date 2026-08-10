# Stub-Adapter.ps1
# ============================================================================
# AI-OS v1.6 — Hermes-compatible ADAPTER BOUNDARY STUB (SIMULATOR)
# ============================================================================
# STATUS: SIMULATED COMPATIBILITY EVIDENCE ONLY.
#   This is NOT Hermes. It does not invoke Hermes, MCP, any API, a browser,
#   credentials, or external tools. It is a local, deterministic, pure
#   PowerShell simulation of the adapter boundary described in
#   HERMES_ADAPTER_CONTRACT.md so that the AI-OS governed task contract can be
#   exercised end-to-end WITHOUT installing or activating any runtime.
#
# REVERSIBILITY / CLEANUP:
#   - Writes nothing outside this pilot's evidence directory.
#   - In-memory state only (idempotency store is per-run, not persisted).
#   - Remove directory 06_Research/pilots/v1.6-hermes/stub/ to fully revert.
#   - No install, no registry, no PATH, no services, no network.
#
# Contract implemented (HERMES_ADAPTER_CONTRACT.md):
#   sec.2 governed task contract (inputs)
#   sec.3 outputs / execution evidence
#   sec.5 approvals (L0-L4, binding, expiry, anti-replay)
#   sec.6 tool/model constraints (scope, credential_ref subset)
#   sec.7 failure semantics (retryable vs non-retryable, fail closed)
#   sec.8 idempotency / retry
#   sec.10 audit fields
# ============================================================================

# --- Deterministic helpers -------------------------------------------------

function Get-StubSha256 {
    param([string]$Text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
        return ([System.BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', '').ToLowerInvariant()
    } finally { $sha.Dispose() }
}

# --- Contract construction (sec.2) ---------------------------------------------

function New-StubTask {
    param(
        [string]$TaskId,
        [string]$IdempotencyKey,
        [string]$ProjectId = 'goffice2026',
        [string]$GovernancePolicyVersion = 'ADR-0013+v4-2026-08-09',
        [string[]]$MandatoryContext,
        [string]$BootstrapAttestation = 'PASS 7/7',
        [string]$QualityGateAttestation = 'PASS 0/0',
        [string]$ExecutionLevel = 'L0',          # L0..L4
        [string]$DataClassification = 'public/internal',
        [string[]]$ApprovedToolScope,
        [string[]]$ApprovedModelScope = @('deepseek-v4-flash'),
        [string]$ApprovalEvidence = '',           # human approval record (L3/L4)
        [string]$ApprovalExpires = '',            # ISO timestamp; empty = never
        [string]$CredentialRef = '',              # task-scoped secret ref (never resolved)
        [string]$BudgetLimits = 'unlimited-sim'
    )
    $ctx = @($MandatoryContext | Sort-Object)
    return [ordered]@{
        task_id                 = $TaskId
        idempotency_key         = $IdempotencyKey
        project_id              = $ProjectId
        governance_policy_version = $GovernancePolicyVersion
        mandatory_context       = @($ctx)
        context_hash            = Get-StubSha256 -Text (($ctx -join "`n"))
        bootstrap_attestation   = $BootstrapAttestation
        quality_gate_attestation= $QualityGateAttestation
        execution_level         = $ExecutionLevel
        data_classification     = $DataClassification
        approved_tool_scope     = @($ApprovedToolScope)
        approved_model_scope    = @($ApprovedModelScope)
        approval_evidence       = $ApprovalEvidence
        approval_expires        = $ApprovalExpires
        credential_ref          = $CredentialRef
        budget_limits           = $BudgetLimits
    }
}

# --- Approval semantics (sec.5) -------------------------------------------------

function Test-StubApproval {
    param([hashtable]$Task, [hashtable]$ApprovalStore)
    $level = [string]$Task.execution_level
    if ($level -in @('L0', 'L1')) {
        return @{ allowed = $true; status = 'auto'; detail = "level $level automatic per policy" }
    }
    if ($level -eq 'L2') {
        return @{ allowed = $true; status = 'policy'; detail = 'L2 policy-controlled write within pilot scope' }
    }
    if ($level -in @('L3', 'L4')) {
        $ev = [string]$Task.approval_evidence
        if (-not $ev) {
            return @{ allowed = $false; status = 'needs_approval'; detail = "level $level requires human approval; none attached" }
        }
        # Binding: approval must reference the same task_id + policy version
        if ($ev -notmatch [regex]::Escape($Task.task_id)) {
            return @{ allowed = $false; status = 'rejected'; detail = "approval replay: record not bound to task_id $($Task.task_id)" }
        }
        if ($ev -notmatch [regex]::Escape($Task.governance_policy_version)) {
            return @{ allowed = $false; status = 'rejected'; detail = 'approval bound to different governance policy version' }
        }
        # Expiry
        if ($Task.approval_expires) {
            $exp = [datetime]::Parse($Task.approval_expires, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AdjustToUniversal)
            if ([datetime]::UtcNow -gt $exp) {
                return @{ allowed = $false; status = 'expired'; detail = "approval expired at $($Task.approval_expires)" }
            }
        }
        return @{ allowed = $true; status = 'approved'; detail = "level $level human approval valid and bound" }
    }
    return @{ allowed = $false; status = 'rejected'; detail = "unknown execution level $level" }
}

# --- Tool / credential scope (sec.6) ---------------------------------------------

function Test-StubScope {
    param([hashtable]$Task, [string]$RequestedTool, [string]$ResolveCredential = '')
    $approved = @($Task.approved_tool_scope)
    if ($RequestedTool -and $RequestedTool -notin $approved) {
        return @{ allowed = $false; status = 'scope_violation'; detail = "tool '$RequestedTool' not in approved_tool_scope" }
    }
    if ($ResolveCredential) {
        if (-not $Task.credential_ref) {
            return @{ allowed = $false; status = 'credential_scope_violation'; detail = 'credential resolution requested but task has no credential_ref' }
        }
        if ($ResolveCredential -ne [string]$Task.credential_ref) {
            return @{ allowed = $false; status = 'credential_scope_violation'; detail = "credential '$ResolveCredential' outside task credential_ref" }
        }
    }
    return @{ allowed = $true; status = 'ok'; detail = 'scope ok' }
}

# --- Context deviation (sec.4) ---------------------------------------------------

function Test-StubContext {
    param([hashtable]$Task, [string[]]$RuntimeContextUsed)
    $allowed = @($Task.mandatory_context)
    $deviations = @($RuntimeContextUsed | Where-Object { $_ -and $_ -notin $allowed })
    if ($deviations.Count -gt 0) {
        return @{ allowed = $false; status = 'context_deviation'; detail = ("unapproved context used: " + ($deviations -join ', ')); deviations = $deviations }
    }
    return @{ allowed = $true; status = 'ok'; detail = 'all runtime context within mandatory set'; deviations = @() }
}

# --- Simulated runtime execution (deterministic, no side effects) ---------------

function Invoke-StubRuntime {
    param([hashtable]$Task, [string]$Tool, [string]$Mode = 'normal')
    # Simulated execution evidence. No real tool runs; result is a deterministic
    # echo derived from the task contract so hashes are reproducible.
    $material = "$($Task.task_id)|$Tool|$($Task.context_hash)|$Mode"
    $payloadHash = Get-StubSha256 -Text $material
    return [ordered]@{
        tool           = $Tool
        payload_hash   = $payloadHash
        simulated_rows = 1
        note           = 'SIMULATED result payload — no real tool invoked'
    }
}

# --- Audit record (sec.10) --------------------------------------------------------

function New-StubAudit {
    param([hashtable]$Task, [string]$Status, [hashtable]$Approval, [hashtable]$Scope, [hashtable]$Context, [string]$RuntimeVersion, [string]$Result, [string[]]$Events, [int]$DurationMs)
    return [ordered]@{
        task_id                = $Task.task_id
        actor                  = 'ai-os-agent-simulated'
        project_id             = $Task.project_id
        context_package_version= $Task.context_hash
        governance_policy_version = $Task.governance_policy_version
        data_classification    = $Task.data_classification
        runtime_version        = $RuntimeVersion
        model_provider         = (@($Task.approved_model_scope) -join ',')
        tools_used             = @($Task.approved_tool_scope)
        approval_status        = $Approval.status
        approval_detail        = $Approval.detail
        scope_status           = $Scope.status
        context_status         = $Context.status
        status                 = $Status
        result                 = $Result
        retryable              = $false
        events                 = @($Events)
        duration_ms            = $DurationMs
        simulated              = $true
    }
}

# --- Main adapter boundary entry -----------------------------------------------

function Invoke-StubAdapter {
    param(
        [hashtable]$Task,
        [string]$RuntimeVersion = 'stub-v0.1.0-simulated',
        [string]$Mode = 'normal',                    # normal | tool_failure | runtime_crash | nonretryable_failure
        [string]$RequestedTool = '',
        [string[]]$RuntimeContextUsed = @(),
        [string]$ResolveCredential = '',
        [hashtable]$ApprovalStore = @{}
    )
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $events = New-Object System.Collections.Generic.List[string]

    # sec.2 completeness
    $required = @('task_id', 'idempotency_key', 'project_id', 'governance_policy_version', 'mandatory_context', 'bootstrap_attestation', 'quality_gate_attestation', 'execution_level', 'approved_tool_scope', 'credential_ref')
    $missing = @($required | Where-Object { -not $Task.ContainsKey($_) -or $null -eq $Task[$_] })
    if ($missing.Count -gt 0) {
        return [ordered]@{ status = 'failed'; error = "contract_incomplete"; detail = ("missing fields: " + ($missing -join ',')); task_id = $Task.task_id; simulated = $true }
    }

    # Idempotency (sec.8): same idempotency_key returns existing result without re-execution
    if ($ApprovalStore.ContainsKey('idem:' + $Task.idempotency_key)) {
        $sw.Stop()
        return [ordered]@{
            status      = 'success'
            task_id     = $Task.task_id
            idempotent  = $true
            idempotency_echo = $ApprovalStore['idem:' + $Task.idempotency_key]
            duration_ms = $sw.ElapsedMilliseconds
            simulated   = $true
            note        = 'duplicate submission suppressed via idempotency_key'
        }
    }

    # sec.5 approval gate
    $approval = Test-StubApproval -Task $Task -ApprovalStore $ApprovalStore
    $events.Add("approval:$($approval.status)")
    if (-not $approval.allowed) {
        $sw.Stop()
        $audit = New-StubAudit -Task $Task -Status $approval.status -Approval $approval -Scope @{ status = 'n/a' } -Context @{ status = 'n/a' } -RuntimeVersion $RuntimeVersion -Result $approval.detail -Events $events -DurationMs $sw.ElapsedMilliseconds
        $ApprovalStore["audit:$($Task.task_id)"] = $audit
        return [ordered]@{ status = $approval.status; task_id = $Task.task_id; detail = $approval.detail; audit = $audit; simulated = $true }
    }

    # sec.6 tool scope (unless we are testing scope violation explicitly)
    if ($Mode -ne 'scope_violation' -and $RequestedTool) {
        $scope = Test-StubScope -Task $Task -RequestedTool $RequestedTool -ResolveCredential $ResolveCredential
        $events.Add("scope:$($scope.status)")
        if (-not $scope.allowed) {
            $sw.Stop()
            $audit = New-StubAudit -Task $Task -Status 'aborted' -Approval $approval -Scope $scope -Context @{ status = 'n/a' } -RuntimeVersion $RuntimeVersion -Result $scope.detail -Events $events -DurationMs $sw.ElapsedMilliseconds
            $ApprovalStore["audit:$($Task.task_id)"] = $audit
            return [ordered]@{ status = 'aborted'; task_id = $Task.task_id; detail = $scope.detail; audit = $audit; simulated = $true }
        }
    } elseif ($Mode -eq 'scope_violation') {
        # explicit scope-violation injection: requested tool is NOT approved
        $scope = @{ allowed = $false; status = 'scope_violation'; detail = "INJECTED: tool '$RequestedTool' not in approved_tool_scope" }
        $events.Add("scope:scope_violation")
        $sw.Stop()
        $audit = New-StubAudit -Task $Task -Status 'aborted' -Approval $approval -Scope $scope -Context @{ status = 'n/a' } -RuntimeVersion $RuntimeVersion -Result $scope.detail -Events $events -DurationMs $sw.ElapsedMilliseconds
        $ApprovalStore["audit:$($Task.task_id)"] = $audit
        return [ordered]@{ status = 'aborted'; task_id = $Task.task_id; detail = $scope.detail; audit = $audit; simulated = $true }
    }

    # sec.4 context handoff immutability
    $ctx = Test-StubContext -Task $Task -RuntimeContextUsed $RuntimeContextUsed
    $events.Add("context:$($ctx.status)")
    if (-not $ctx.allowed) {
        $sw.Stop()
        $audit = New-StubAudit -Task $Task -Status 'aborted' -Approval $approval -Scope @{ status = 'ok' } -Context $ctx -RuntimeVersion $RuntimeVersion -Result $ctx.detail -Events $events -DurationMs $sw.ElapsedMilliseconds
        $ApprovalStore["audit:$($Task.task_id)"] = $audit
        return [ordered]@{ status = 'aborted'; task_id = $Task.task_id; detail = $ctx.detail; deviations = $ctx.deviations; audit = $audit; simulated = $true }
    }

    # sec.7 failure injection (before execution)
    if ($Mode -eq 'tool_failure') {
        $sw.Stop()
        $audit = New-StubAudit -Task $Task -Status 'failed' -Approval $approval -Scope @{ status = 'ok' } -Context $ctx -RuntimeVersion $RuntimeVersion -Result 'simulated transient tool failure' -Events @($events + 'failure:tool_transient') -DurationMs $sw.ElapsedMilliseconds
        $audit.retryable = $true
        $ApprovalStore["audit:$($Task.task_id)"] = $audit
        return [ordered]@{ status = 'failed'; task_id = $Task.task_id; retryable = $true; detail = 'simulated transient tool failure'; audit = $audit; simulated = $true }
    }
    if ($Mode -eq 'nonretryable_failure') {
        $sw.Stop()
        $audit = New-StubAudit -Task $Task -Status 'failed' -Approval $approval -Scope @{ status = 'ok' } -Context $ctx -RuntimeVersion $RuntimeVersion -Result 'simulated non-retryable policy failure' -Events @($events + 'failure:policy_nonretryable') -DurationMs $sw.ElapsedMilliseconds
        $audit.retryable = $false
        $ApprovalStore["audit:$($Task.task_id)"] = $audit
        return [ordered]@{ status = 'failed'; task_id = $Task.task_id; retryable = $false; detail = 'simulated non-retryable policy failure'; audit = $audit; simulated = $true }
    }
    if ($Mode -eq 'runtime_crash') {
        # Simulated crash: no result payload produced, no mutation applied.
        $sw.Stop()
        $audit = New-StubAudit -Task $Task -Status 'aborted' -Approval $approval -Scope @{ status = 'ok' } -Context $ctx -RuntimeVersion $RuntimeVersion -Result 'simulated runtime crash — no side effects applied, state intact' -Events @($events + 'failure:runtime_crash') -DurationMs $sw.ElapsedMilliseconds
        $audit.retryable = $true
        $ApprovalStore["audit:$($Task.task_id)"] = $audit
        return [ordered]@{ status = 'failed'; task_id = $Task.task_id; retryable = $true; detail = 'simulated runtime crash; recovery via retry with same idempotency_key'; audit = $audit; simulated = $true }
    }

    # Normal execution
    $tool = if ($RequestedTool) { $RequestedTool } else { 'simulated-read' }
    $result = Invoke-StubRuntime -Task $Task -Tool $tool -Mode $Mode
    $sw.Stop()
    $audit = New-StubAudit -Task $Task -Status 'success' -Approval $approval -Scope @{ status = 'ok' } -Context $ctx -RuntimeVersion $RuntimeVersion -Result 'task executed; result payload recorded' -Events @($events + 'executed') -DurationMs $sw.ElapsedMilliseconds
    $ApprovalStore["audit:$($Task.task_id)"] = $audit
    $ApprovalStore["idem:" + $Task.idempotency_key] = $result.payload_hash

    return [ordered]@{
        status      = 'success'
        task_id     = $Task.task_id
        idempotent  = $false
        result      = $result
        audit       = $audit
        simulated   = $true
    }
}
