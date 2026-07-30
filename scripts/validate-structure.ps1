<#
.SYNOPSIS
  Validates required folders and memory/governance files for AI Operating System v1.
.DESCRIPTION
  Run from repo root:
    pwsh -File scripts/validate-structure.ps1
    # or Windows PowerShell 5.x:
    powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-structure.ps1
  Exit 0 on pass, 1 on fail. Prints PASS/FAIL per check.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$Root = Resolve-Path (Join-Path $PSScriptRoot '..')
$failed = 0

function Test-RequiredPath {
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][ValidateSet('Directory', 'File')][string]$Kind
    )
    $full = Join-Path $Root $RelativePath
    $ok = if ($Kind -eq 'Directory') {
        Test-Path -LiteralPath $full -PathType Container
    } else {
        Test-Path -LiteralPath $full -PathType Leaf
    }
    if ($ok) {
        Write-Host "PASS  [$Kind] $RelativePath"
    } else {
        Write-Host "FAIL  [$Kind] $RelativePath"
        $script:failed++
    }
}

$requiredFolders = @(
    '00_Dashboard',
    '01_Projects',
    '02_Knowledge',
    '03_Architecture',
    '04_ADR',
    '05_Meetings',
    '06_Research',
    '07_Memory',
    '08_Skills',
    '09_SOP',
    '10_Releases',
    '11_Templates',
    'Archive',
    'scripts'
)

$requiredFiles = @(
    'README.md',
    '07_Memory/OPERATING_RULES.md',
    '07_Memory/SYSTEM_MEMORY.md',
    '07_Memory/CURRENT_STATE.md',
    '07_Memory/SESSION_INDEX.md',
    '07_Memory/DECISION_MEMORY.md',
    '07_Memory/SESSION_BOOTSTRAP.md',
    '07_Memory/SESSION_CLOSE.md',
    '04_ADR/ADR-TEMPLATE.md',
    '04_ADR/ADR-0001-local-first-development.md',
    '04_ADR/ADR-0002-github-source-of-truth.md',
    '04_ADR/ADR-0003-obsidian-knowledge-interface.md',
    '04_ADR/ADR-0004-hermes-deferred-phase-2.md',
    '11_Templates/PROJECT_TEMPLATE.md',
    '11_Templates/AGENT_TASK_TEMPLATE.md',
    '11_Templates/SOP_TEMPLATE.md',
    '11_Templates/SESSION_HANDOFF_TEMPLATE.md',
    '11_Templates/RELEASE_TEMPLATE.md'
)

Write-Host "Validating structure under: $Root"
Write-Host ""

foreach ($dir in $requiredFolders) {
    Test-RequiredPath -RelativePath $dir -Kind Directory
}

Write-Host ""

foreach ($file in $requiredFiles) {
    Test-RequiredPath -RelativePath $file -Kind File
}

Write-Host ""
if ($failed -eq 0) {
    Write-Host "RESULT: PASS (all checks ok)"
    exit 0
} else {
    Write-Host "RESULT: FAIL ($failed check(s) failed)"
    exit 1
}
