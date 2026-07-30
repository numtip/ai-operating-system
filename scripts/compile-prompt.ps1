<#
.SYNOPSIS
  CLI entrypoint for AI-OS Prompt Compiler Runtime (v1.3).
.DESCRIPTION
  Compiles Project + Goal + Model Profile + Constraints into Head/Subagent prompts.
  No LLM. No network. Stdlib PowerShell only.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts/compile-prompt.ps1 `
    -Project goffice2026 `
    -Goal "Audit production readiness without modifying the external repository." `
    -ModelProfile deepseek-v4-pro

.EXAMPLE
  pwsh -File scripts/compile-prompt.ps1 -Project document-center `
    -Goal "Inspect publication pipeline readiness and identify blocking issues." `
    -ModelProfile claude-coding -OutputMode json -OutDir out/compile
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Project,

    [Parameter(Mandatory = $true)]
    [AllowEmptyString()]
    [string]$Goal,

    [Parameter(Mandatory = $true)]
    [Alias('Model')]
    [string]$ModelProfile,

    [string[]]$Constraints = @(),

    [ValidateSet('json', 'markdown', 'both')]
    [string]$OutputMode = 'both',

    [string]$RepoRoot = '',

    [string]$OutDir = '',

    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$Root = if ($RepoRoot) {
    [string](Resolve-Path -LiteralPath $RepoRoot)
}
else {
    [string](Resolve-Path (Join-Path $PSScriptRoot '..'))
}

$runtime = Join-Path $Root 'prompt-compiler/runtime/Compile-Prompt.ps1'
if (-not (Test-Path -LiteralPath $runtime -PathType Leaf)) {
    Write-Error "Runtime missing: prompt-compiler/runtime/Compile-Prompt.ps1"
    exit 2
}

. $runtime

$result = Invoke-PromptCompile `
    -Project $Project `
    -Goal $Goal `
    -ModelProfile $ModelProfile `
    -Constraints $Constraints `
    -OutputMode $OutputMode `
    -RepoRoot $Root

$json = $result | ConvertTo-Json -Depth 12
$md = Format-CompilerMarkdown -Result $result

if ($OutDir) {
    $outFull = if ([IO.Path]::IsPathRooted($OutDir)) { $OutDir } else { Join-Path $Root ($OutDir -replace '/', [IO.Path]::DirectorySeparatorChar) }
    if (-not (Test-Path -LiteralPath $outFull -PathType Container)) {
        New-Item -ItemType Directory -Path $outFull -Force | Out-Null
    }
    $utf8 = New-Object System.Text.UTF8Encoding $false
    if ($OutputMode -eq 'json' -or $OutputMode -eq 'both') {
        [System.IO.File]::WriteAllText((Join-Path $outFull 'compile-result.json'), $json + "`n", $utf8)
    }
    if ($OutputMode -eq 'markdown' -or $OutputMode -eq 'both') {
        [System.IO.File]::WriteAllText((Join-Path $outFull 'compile-result.md'), $md, $utf8)
        if ($result.status -eq 'ok' -and $result.head_agent_prompt) {
            [System.IO.File]::WriteAllText((Join-Path $outFull 'head-agent-prompt.md'), $result.head_agent_prompt, $utf8)
        }
    }
    if (-not $Quiet) {
        Write-Host "Wrote outputs under: $outFull"
    }
}

if (-not $Quiet) {
    if ($OutputMode -eq 'json') {
        Write-Output $json
    }
    elseif ($OutputMode -eq 'markdown') {
        Write-Output $md
    }
    else {
        Write-Output $md
        Write-Host ''
        Write-Host '--- JSON (metrics) ---'
        Write-Host ($result.metrics | ConvertTo-Json -Compress)
    }
}

if ($result.status -eq 'ok') { exit 0 } else { exit 1 }
