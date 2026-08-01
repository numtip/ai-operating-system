<#
.SYNOPSIS
  Deterministic tests for Prompt Compiler Runtime (v1.3).
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File prompt-compiler/tests/run-tests.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = [string](Resolve-Path (Join-Path $PSScriptRoot '../..'))
$runtime = Join-Path $Root 'prompt-compiler/runtime/Compile-Prompt.ps1'
. $runtime

$passed = 0
$failed = 0
$warnings = 0
$results = New-Object System.Collections.Generic.List[object]

function Assert-True {
    param([string]$Name, [bool]$Condition, [string]$Detail = '')
    if ($Condition) {
        $script:passed++
        $script:results.Add([ordered]@{ name = $Name; status = 'PASS'; detail = $Detail }) | Out-Null
        Write-Host "PASS  $Name"
    }
    else {
        $script:failed++
        $script:results.Add([ordered]@{ name = $Name; status = 'FAIL'; detail = $Detail }) | Out-Null
        Write-Host "FAIL  $Name  $Detail"
    }
}

function Assert-Contains {
    param([string]$Name, $Haystack, [string]$Needle)
    $ok = $false
    if ($null -ne $Haystack) {
        $text = if ($Haystack -is [string]) { $Haystack } else { ($Haystack | Out-String) }
        $ok = $text.IndexOf($Needle, [StringComparison]::OrdinalIgnoreCase) -ge 0
    }
    Assert-True -Name $Name -Condition $ok -Detail "expected to contain: $Needle"
}

# --- 1. valid project ---
$r1 = Invoke-PromptCompile -Project 'goffice2026' -Goal 'Audit production readiness without modifying the external repository.' -ModelProfile 'deepseek-v4-pro' -RepoRoot $Root -OutputMode both
Assert-True '1.valid_project_status_ok' ($r1.status -eq 'ok') ($r1.errors -join '; ')
Assert-True '1.valid_project_has_head_prompt' (-not [string]::IsNullOrWhiteSpace($r1.head_agent_prompt))
Assert-True '1.valid_project_has_subagents' (@($r1.subagent_prompts).Count -ge 1)
Assert-Contains '1.valid_project_goal_in_prompt' $r1.head_agent_prompt 'Audit production readiness'

# --- 2. missing project ---
$r2 = Invoke-PromptCompile -Project 'does-not-exist-xyz' -Goal 'Do something measurable.' -ModelProfile 'generic-reasoning' -RepoRoot $Root -OutputMode json
Assert-True '2.missing_project_errors' ($r2.status -eq 'error')
Assert-True '2.missing_project_code' (@($r2.errors | Where-Object { $_ -match 'missing_project' }).Count -ge 1)

# --- 3. unknown model profile ---
$r3 = Invoke-PromptCompile -Project 'goffice2026' -Goal 'Audit production readiness without modifying the external repository.' -ModelProfile 'not-a-real-profile' -RepoRoot $Root -OutputMode json
Assert-True '3.unknown_profile_errors' ($r3.status -eq 'error')
Assert-True '3.unknown_profile_code' (@($r3.errors | Where-Object { $_ -match 'unknown_model_profile' }).Count -ge 1)

# --- 4. empty goal ---
$r4 = Invoke-PromptCompile -Project 'goffice2026' -Goal '' -ModelProfile 'generic-reasoning' -RepoRoot $Root -OutputMode json
Assert-True '4.empty_goal_errors' ($r4.status -eq 'error')
Assert-True '4.empty_goal_code' (@($r4.errors | Where-Object { $_ -match 'empty_goal' }).Count -ge 1)

# --- 5. conflicting constraints ---
$r5 = Invoke-PromptCompile -Project 'goffice2026' -Goal 'Implement a small docs tweak.' -ModelProfile 'cursor-coding' -Constraints @('read-only', 'allow-write') -RepoRoot $Root -OutputMode json
Assert-True '5.conflicting_constraints_errors' ($r5.status -eq 'error')
Assert-True '5.conflicting_constraints_code' (@($r5.errors | Where-Object { $_ -match 'conflicting_constraints' }).Count -ge 1)

# --- 6. deterministic repeat ---
$r6a = Invoke-PromptCompile -Project 'goffice2026' -Goal 'Audit production readiness without modifying the external repository.' -ModelProfile 'deepseek-v4-pro' -RepoRoot $Root -OutputMode both
$r6b = Invoke-PromptCompile -Project 'goffice2026' -Goal 'Audit production readiness without modifying the external repository.' -ModelProfile 'deepseek-v4-pro' -RepoRoot $Root -OutputMode both
Assert-True '6.deterministic_hash_match' ($r6a.metrics.deterministic_hash -eq $r6b.metrics.deterministic_hash) ("a=$($r6a.metrics.deterministic_hash) b=$($r6b.metrics.deterministic_hash)")
Assert-True '6.deterministic_prompt_match' ($r6a.head_agent_prompt -eq $r6b.head_agent_prompt)

# --- 7. bounded subagent prompts ---
$r7 = Invoke-PromptCompile -Project 'goffice2026' -Goal 'Audit production readiness without modifying the external repository.' -ModelProfile 'deepseek-v4-pro' -RepoRoot $Root -OutputMode both
$bounded = $true
$detail7 = ''
foreach ($s in @($r7.subagent_prompts)) {
    $words = @($s.prompt -split '\s+' | Where-Object { $_ })
    if ($words.Count -gt 400) { $bounded = $false; $detail7 = "$($s.id) words=$($words.Count)" }
    if ($s.prompt -notmatch 'Assigned objective') { $bounded = $false; $detail7 = "$($s.id) missing objective" }
    if ($s.prompt -notmatch 'Forbidden scope') { $bounded = $false; $detail7 = "$($s.id) missing forbidden" }
    if ($s.prompt -notmatch 'Handoff format') { $bounded = $false; $detail7 = "$($s.id) missing handoff" }
    if ($s.prompt -notmatch 'Output limit') { $bounded = $false; $detail7 = "$($s.id) missing output limit" }
}
Assert-True '7.bounded_subagent_prompts' ($bounded -and $r7.status -eq 'ok') $detail7
Assert-True '7.subagent_no_overlap_ids' ((@($r7.subagent_prompts | ForEach-Object { $_.id } | Sort-Object -Unique).Count) -eq @($r7.subagent_prompts).Count)

# --- 8. broken canonical reference ---
# Simulate by pointing RepoRoot at a temp incomplete tree is heavy; instead call Select via missing required OPERATING_RULES is not practical.
# Use a project adapter with required in-vault doc that does not exist.
$tmpProj = Join-Path $Root '01_Projects/_compiler-test-broken'
try {
    New-Item -ItemType Directory -Path $tmpProj -Force | Out-Null
    $adapter = @'
# Project Adapter: _compiler-test-broken

## 1. Metadata

| Field | Value |
|-------|-------|
| project_id | _compiler-test-broken |
| display_name | Broken Test |
| status | draft |
| owner | test |
| adapter_version | 1.0 |
| location_kind | in_vault |

## 2. Repository

| Field | Value |
|-------|-------|
| vault_path | 01_Projects/_compiler-test-broken/ |
| remote_url | |
| default_branch | |
| tip_commit | |
| notes | test only |

## 3. Current state

| Field | Value |
|-------|-------|
| summary | intentional broken required canonical |
| as_of | 2026-07-30 |
| detail_ref | |

## 4. Canonical documents

| role | path | required | notes |
|------|------|----------|-------|
| readme | README.md | true | missing on purpose |

## 5. Memory entry

| Field | Value |
|-------|-------|
| memory_path | 07_Memory/projects/_compiler-test-broken.md |

## 6. Bootstrap path

| Field | Value |
|-------|-------|
| ai_os_bootstrap | 09_SOP/AGENT_BOOTSTRAP.md |
| adapter_ref | 01_Projects/_compiler-test-broken/ADAPTER.md |
| project_entry | test |
| extra_steps | none |
'@
    [System.IO.File]::WriteAllText((Join-Path $tmpProj 'ADAPTER.md'), $adapter)
    $r8 = Invoke-PromptCompile -Project '_compiler-test-broken' -Goal 'Inspect publication pipeline readiness and identify blocking issues.' -ModelProfile 'generic-reasoning' -RepoRoot $Root -OutputMode json
    Assert-True '8.broken_canonical_fails' ($r8.status -eq 'error') ($r8.errors -join '; ')
    Assert-True '8.broken_canonical_code' (@($r8.errors | Where-Object { $_ -match 'broken_canonical_reference' }).Count -ge 1) ($r8.errors -join '; ')
}
finally {
    if (Test-Path -LiteralPath $tmpProj) {
        Remove-Item -LiteralPath $tmpProj -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# --- 9. index miss ---
$r9 = Invoke-PromptCompile -Project 'document-center' -Goal 'Inspect publication pipeline readiness and identify blocking issues.' -ModelProfile 'claude-coding' -RepoRoot $Root -OutputMode both
# document-center may or may not be in index; if not, warning index_miss; if yes, ok without that warning
$hasMissWarn = @($r9.warnings | Where-Object { $_ -match 'index_miss' }).Count -ge 1
$inIndex = $false
$idx = Get-Content (Join-Path $Root '12_Indexes/project_index.json') -Raw | ConvertFrom-Json
foreach ($e in @($idx.entries)) {
    if (([string]$e.path) -match 'document-center' -or ([string]$e.id) -match 'document-center') { $inIndex = $true }
}
if ($inIndex) {
    Assert-True '9.index_miss_or_hit_consistent' (-not $hasMissWarn) 'project in index should not warn index_miss'
    Assert-True '9.document_center_compiles' ($r9.status -eq 'ok') ($r9.errors -join '; ')
}
else {
    Assert-True '9.index_miss_warning' $hasMissWarn ($r9.warnings -join '; ')
    Assert-True '9.document_center_still_compiles_via_folder' ($r9.status -eq 'ok') ($r9.errors -join '; ')
}

# --- 10. safe path handling ---
$safeOk = $true
$safeDetail = ''
try {
    $null = Resolve-RepoPath -RelPath '../outside' -RepoRoot $Root
    $safeOk = $false
    $safeDetail = 'traversal not rejected'
}
catch {
    $safeOk = $true
}
Assert-True '10.safe_path_traversal_rejected' $safeOk $safeDetail
try {
    $null = Resolve-RepoPath -RelPath 'C:\Windows\System32' -RepoRoot $Root
    Assert-True '10.safe_path_absolute_rejected' $false 'absolute path not rejected'
}
catch {
    Assert-True '10.safe_path_absolute_rejected' $true
}
# compiled output must not contain drive paths
Assert-True '10.no_abs_path_in_goffice_prompt' ($r1.head_agent_prompt -notmatch '[A-Za-z]:\\') 'absolute path leaked'
Assert-True '10.no_goffice_leak_into_document_center' (
    $r9.status -ne 'ok' -or (
        $r9.head_agent_prompt -notmatch 'goffice2026' -and
        ($r9.head_agent_prompt + ($r9.subagent_prompts | ForEach-Object { $_.prompt } | Out-String)) -match 'document-center'
    )
) 'cross-project leak or missing project id'

# Cross-pilot isolation extra check
if ($r1.status -eq 'ok' -and $r9.status -eq 'ok') {
    $dcBlob = $r9.head_agent_prompt + (($r9.subagent_prompts | ForEach-Object { $_.prompt }) -join '')
    Assert-True '10.document_center_forbids_goffice_instructions' ($dcBlob -match 'Do not load goffice2026|other projects|Do not leak|no cross-project' -or $dcBlob -notmatch 'GOffice 2026') 
}

# --- 11. deterministic optimizer ---
$r11a = Invoke-PromptCompile -Project 'goffice2026' -Goal 'Audit production readiness without modifying the external repository.' -ModelProfile 'deepseek-v4-pro' -RepoRoot $Root -OutputMode both
$r11b = Invoke-PromptCompile -Project 'goffice2026' -Goal 'Audit production readiness without modifying the external repository.' -ModelProfile 'deepseek-v4-pro' -RepoRoot $Root -OutputMode both
Assert-True '11.optimizer_deterministic_hash' ($r11a.metrics.deterministic_hash -eq $r11b.metrics.deterministic_hash) ("a=$($r11a.metrics.deterministic_hash) b=$($r11b.metrics.deterministic_hash)")
Assert-True '11.optimizer_deterministic_file_list' ((@($r11a.context_manifest.context_files) -join '|') -eq (@($r11b.context_manifest.context_files) -join '|'))
Assert-True '11.optimization_metrics_present' ($null -ne $r11a.metrics.optimization -and $null -ne $r11a.metrics.quality_gate)

# --- 12. mandatory context preserved ---
$mandatoryPaths = @(
    '07_Memory/OPERATING_RULES.md',
    '07_Memory/SYSTEM_MEMORY.md',
    '07_Memory/CURRENT_STATE.md',
    '12_Indexes/project_index.json',
    '01_Projects/goffice2026/ADAPTER.md'
)
$allMandatory = $true
$missingMandatory = @()
foreach ($mp in $mandatoryPaths) {
    if (-not (@($r11a.context_manifest.context_files) -contains $mp)) { $allMandatory = $false; $missingMandatory += $mp }
}
Assert-True '12.mandatory_paths_present' $allMandatory ("missing: $($missingMandatory -join ', ')")
$requiredOk = $true
foreach ($e in @($r11a.context_manifest.selected)) {
    if ($e.required -and -not (@($r11a.context_manifest.context_files) -contains $e.path)) { $requiredOk = $false }
}
Assert-True '12.required_entries_in_selection' $requiredOk

# --- 13. duplicate elimination ---
$dupContext = [ordered]@{
    selected = @(
        [ordered]@{ path = '07_Memory/OPERATING_RULES.md'; source = 'bootstrap'; reason = 'operating_rules'; required = $true },
        [ordered]@{ path = '07_memory/operating_rules.md'; source = 'bootstrap'; reason = 'operating_rules'; required = $true },
        [ordered]@{ path = '07_Memory\OPERATING_RULES.md'; source = 'bootstrap'; reason = 'operating_rules'; required = $false },
        [ordered]@{ path = '02_Knowledge/audit-readiness-notes.md'; source = 'knowledge_index'; reason = 'goal_match'; required = $false }
    )
    operating_rules = @()
    index_hits = 0
    warnings = @()
    errors = @()
}
$mockNorm13 = [ordered]@{ goal = 'Audit production readiness without modifying the external repository.'; constraints = @(); inferred_read_only = $true }
$mockProf13 = [ordered]@{ profile = [pscustomobject]@{ context_limit_policy = [pscustomobject]@{ max_context_refs = 10 } } }
$opt13a = Optimize-CompilerContext -Context $dupContext -Normalized $mockNorm13 -ProfileInfo $mockProf13
Assert-True '13.duplicates_removed' (@($opt13a.selected).Count -eq 2) ("selected=$(@($opt13a.selected).Count)")
Assert-True '13.duplicate_path_rejected' (@($opt13a.rejected | Where-Object { $_.reason -eq 'duplicate_path' }).Count -eq 2) (@($opt13a.rejected | ForEach-Object { "$($_.path):$($_.reason)" }) -join '; ')

# --- 14. budget enforcement ---
$budEntries = @()
foreach ($p in @('07_Memory/OPERATING_RULES.md', '07_Memory/SYSTEM_MEMORY.md', '12_Indexes/project_index.json')) {
    $budEntries += [ordered]@{ path = $p; source = 'bootstrap'; reason = 'required_doc'; required = $true }
}
for ($i = 1; $i -le 8; $i++) {
    $budEntries += [ordered]@{ path = ("02_Knowledge/audit-note-{0:D2}.md" -f $i); source = 'knowledge_index'; reason = 'goal_match'; required = $false }
}
$budContext = [ordered]@{ selected = @($budEntries); operating_rules = @(); index_hits = 0; warnings = @(); errors = @() }
$mockNorm14 = [ordered]@{ goal = 'audit note readiness review'; constraints = @(); inferred_read_only = $true }
$mockProf14 = [ordered]@{ profile = [pscustomobject]@{
        context_limit_policy = [pscustomobject]@{ max_context_refs = 9 }
        context_budget       = [pscustomobject]@{ max_files = 9; max_tokens = 0 }
    } }
$opt14a = Optimize-CompilerContext -Context $budContext -Normalized $mockNorm14 -ProfileInfo $mockProf14
$opt14b = Optimize-CompilerContext -Context $budContext -Normalized $mockNorm14 -ProfileInfo $mockProf14
Assert-True '14.budget_total_within_limit' (@($opt14a.selected).Count -le 9) ("selected=$(@($opt14a.selected).Count)")
Assert-True '14.budget_required_all_kept' ((@($opt14a.selected | Where-Object { $_.required }).Count) -eq 3)
Assert-True '14.budget_rejected_count' (@($opt14a.rejected).Count -eq 2) ("rejected=$(@($opt14a.rejected).Count)")
Assert-True '14.budget_deterministic' ((@($opt14a.selected | ForEach-Object { $_.path }) -join '|') -eq (@($opt14b.selected | ForEach-Object { $_.path }) -join '|'))

# --- 15. prompt quality gate valid case ---
Assert-True '15.quality_gate_zero_errors_valid' ($r1.status -eq 'ok' -and $r1.metrics.quality_gate.errors -eq 0) ("errors=$($r1.metrics.quality_gate.errors) $($r1.errors -join '; ')")

# --- 16. prompt quality gate invalid cases ---
$mockProf16 = [ordered]@{ profile = [pscustomobject]@{ tool_use_guidance = 'no-network' } }
$mockNorm16 = [ordered]@{ goal = 'Audit production readiness without modifying the external repository.'; constraints = @(); inferred_read_only = $true }
$goodSub = @([pscustomobject]@{ id = 'sg1'; prompt = "## Subagent: sg1`n## Assigned objective`nx`n## Forbidden scope`nx`n## Output limit`nx`n## Handoff format`nx" })
$badHead = "# Head`n## Goal`nx`nRun git push origin main to publish the results now."
$g16a = Assert-PromptQualityGate -HeadPrompt $badHead -Subagents $goodSub -Normalized $mockNorm16 -ProfileInfo $mockProf16
Assert-True '16a.prohibited_action_error' (@($g16a.errors | Where-Object { $_ -match 'quality_gate' }).Count -ge 1) ($g16a.errors -join '; ')
$badSub = @([pscustomobject]@{ id = 'sg2'; prompt = "## Subagent: sg2`n## Assigned objective`nx`n## Forbidden scope`nx`n## Output limit`nx" })
$g16b = Assert-PromptQualityGate -HeadPrompt '# Head prompt' -Subagents $badSub -Normalized $mockNorm16 -ProfileInfo $mockProf16
Assert-True '16b.subagent_missing_handoff_error' (@($g16b.errors | Where-Object { $_ -match 'quality_gate' -and $_ -match 'Handoff format' }).Count -ge 1) ($g16b.errors -join '; ')
$longHead = ('word ' * 1250).Trim()
$g16c = Assert-PromptQualityGate -HeadPrompt $longHead -Subagents $goodSub -Normalized $mockNorm16 -ProfileInfo $mockProf16
Assert-True '16c.head_over_1200_words_error' (@($g16c.errors | Where-Object { $_ -match 'quality_gate' -and $_ -match '1200' }).Count -ge 1) ($g16c.errors -join '; ')
$secretHead = "# Head`nUse credential api_key = `"abcdef123456`" for the service call."
$g16d = Assert-PromptQualityGate -HeadPrompt $secretHead -Subagents $goodSub -Normalized $mockNorm16 -ProfileInfo $mockProf16
Assert-True '16d.hardcoded_secret_error' (@($g16d.errors | Where-Object { $_ -match 'quality_gate' -and $_ -match 'secret' }).Count -ge 1) ($g16d.errors -join '; ')

# --- 17. pilot budget acceptance ---
$r17 = Invoke-PromptCompile -Project 'goffice2026' -Goal 'Audit production readiness without modifying the external repository.' -ModelProfile 'deepseek-v4-pro' -RepoRoot $Root -OutputMode both
Assert-True '17.pilot_status_ok' ($r17.status -eq 'ok') ($r17.errors -join '; ')
Assert-True '17.pilot_files_within_budget' ($r17.metrics.context_files_selected -le 10) ("selected=$($r17.metrics.context_files_selected)")
$mandatoryOk17 = $true
foreach ($mp in $mandatoryPaths) {
    if (-not (@($r17.context_manifest.context_files) -contains $mp)) { $mandatoryOk17 = $false }
}
Assert-True '17.pilot_mandatory_preserved' $mandatoryOk17

# --- 18. required entry preserved on normalized-path collision (defect fix) ---
# Optional (kept, path contains goal token 'audit') seen first, then a required
# entry with the same normalized path collides -> required must win.
$collContext = [ordered]@{
    selected = @(
        [ordered]@{ path = '02_Knowledge/audit-operating-rules.md'; source = 'knowledge_index'; reason = 'goal_match'; required = $false },
        [ordered]@{ path = '02_Knowledge/AUDIT-Operating-Rules.md'; source = 'bootstrap'; reason = 'operating_rules'; required = $true }
    )
    operating_rules = @()
    index_hits = 0
    warnings = @()
    errors = @()
}
$mockNorm18 = [ordered]@{ goal = 'Audit production readiness without modifying the external repository.'; constraints = @(); inferred_read_only = $true }
$mockProf18 = [ordered]@{ profile = [pscustomobject]@{ context_limit_policy = [pscustomobject]@{ max_context_refs = 10 } } }
$opt18 = Optimize-CompilerContext -Context $collContext -Normalized $mockNorm18 -ProfileInfo $mockProf18
$reqKept18 = @($opt18.selected | Where-Object { $_.required -and $_.path -eq '02_Knowledge/AUDIT-Operating-Rules.md' }).Count
Assert-True '18.required_kept_on_collision' ($reqKept18 -eq 1) ("selected=$(@($opt18.selected | ForEach-Object { $_.path }) -join '; ')")
Assert-True '18.optional_duplicate_rejected' (@($opt18.rejected | Where-Object { $_.reason -eq 'duplicate_path' }).Count -eq 1) (@($opt18.rejected | ForEach-Object { "$($_.path):$($_.reason)" }) -join '; ')

# --- 19. quality gate negation + unquoted secret (defect fixes) ---
$mockProf19 = [ordered]@{ profile = [pscustomobject]@{ tool_use_guidance = 'no-network' } }
$mockNorm19 = [ordered]@{ goal = 'Audit production readiness without modifying the external repository.'; constraints = @(); inferred_read_only = $true }
$goodSub19 = @([pscustomobject]@{ id = 'sg1'; prompt = "## Subagent: sg1`n## Assigned objective`nx`n## Forbidden scope`nx`n## Output limit`nx`n## Handoff format`nx" })
# Negated prohibition must NOT trigger the gate
$negHead = "# Head`n## Goal`nx`nDo not git push or deploy anything. Never call Invoke-WebRequest."
$g19a = Assert-PromptQualityGate -HeadPrompt $negHead -Subagents $goodSub19 -Normalized $mockNorm19 -ProfileInfo $mockProf19
Assert-True '19.negated_prohibition_no_error' (@($g19a.errors).Count -eq 0) ($g19a.errors -join '; ')
# Unquoted secret must trigger the gate
$unqHead = "# Head`n## Goal`nx`nUse api_key = abcdef1234567890 for the service call."
$g19b = Assert-PromptQualityGate -HeadPrompt $unqHead -Subagents $goodSub19 -Normalized $mockNorm19 -ProfileInfo $mockProf19
Assert-True '19.unquoted_secret_error' (@($g19b.errors | Where-Object { $_ -match 'quality_gate' -and $_ -match 'secret' }).Count -ge 1) ($g19b.errors -join '; ')

Write-Host ''
Write-Host ("SUMMARY passed={0} failed={1} warnings_logged={2}" -f $passed, $failed, $warnings)
if ($failed -gt 0) { exit 1 } else { exit 0 }
