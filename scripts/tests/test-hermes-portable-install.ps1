[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$installer = Join-Path $repoRoot 'scripts\Install-HermesObsidianMemory.ps1'
$lockPath = Join-Path $repoRoot 'scripts\hermes-install.lock.json'
$passed = 0
$failed = 0

function Assert-True {
    param([bool]$Condition, [string]$Name)
    if ($Condition) {
        $script:passed++
        Write-Output "PASS  $Name"
    }
    else {
        $script:failed++
        Write-Output "FAIL  $Name"
    }
}

$lock = Get-Content -Raw -LiteralPath $lockPath | ConvertFrom-Json
Assert-True ($lock.ai_os_release -eq 'v1.6.0-alpha.2') 'lock.ai_os_release'
Assert-True ($lock.hermes.tag -eq 'v2026.8.3') 'lock.hermes.tag'
Assert-True ($lock.hermes.version -eq '0.20.0') 'lock.hermes.version'
Assert-True ($lock.hermes.commit -eq '3c27eb6234bf91b8ceee9e9071591b31e9b148cb') 'lock.hermes.commit'
Assert-True ($lock.hermes.mcp_version -eq '1.28.1') 'lock.mcp_version'
Assert-True ($lock.hermes.starlette_version -eq '1.3.1') 'lock.starlette_version'

$planText = powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer `
    -ProjectRoot 'D:\PortableProjects' `
    -HermesInstallRoot 'D:\PortableTools\hermes-agent' `
    -HermesHome 'D:\PortableData\hermes' `
    -CodexHome 'D:\PortableData\codex' `
    -CursorHome 'D:\PortableData\cursor' `
    -VSCodeUserDir 'D:\PortableData\vscode-user' `
    -LauncherDirectory 'D:\PortableBin' `
    -InstallObsidian `
    -OpenObsidian `
    -PlanOnly
$planExit = $LASTEXITCODE
$plan = $planText | ConvertFrom-Json
Assert-True ($planExit -eq 0) 'plan.exit_0'
Assert-True ($plan.project_root -eq 'D:\PortableProjects') 'plan.project_root'
Assert-True ($plan.hermes_install_root -eq 'D:\PortableTools\hermes-agent') 'plan.install_root'
Assert-True ($plan.hermes_home -eq 'D:\PortableData\hermes') 'plan.hermes_home'
Assert-True ($plan.codex_home -eq 'D:\PortableData\codex') 'plan.codex_home'
Assert-True ($plan.cursor_home -eq 'D:\PortableData\cursor') 'plan.cursor_home'
Assert-True ($plan.vscode_user_dir -eq 'D:\PortableData\vscode-user') 'plan.vscode_user_dir'
Assert-True ($plan.cursor_mcp -eq 'D:\PortableData\cursor\mcp.json') 'plan.cursor_mcp'
Assert-True ($plan.cursor_plugin -eq 'D:\PortableData\cursor\plugins\local\ai-os-hermes-worker') 'plan.cursor_plugin'
Assert-True ($plan.vscode_mcp -eq 'D:\PortableData\vscode-user\mcp.json') 'plan.vscode_mcp'
Assert-True ($plan.configure_cursor -and $plan.configure_vscode) 'plan.ide_adapters_default_on'
Assert-True ($plan.launcher_directory -eq 'D:\PortableBin') 'plan.launcher_directory'
Assert-True ($plan.hermes_commit -eq $lock.hermes.commit) 'plan.pin_matches_lock'
Assert-True ($plan.install_obsidian -and $plan.open_obsidian) 'plan.obsidian_flags'
Assert-True ($plan.seed_bundled_skills) 'plan.bundled_skills_default_on'

$skipPlanText = powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer `
    -ProjectRoot 'D:\PortableProjects' `
    -HermesInstallRoot 'D:\PortableTools\hermes-agent' `
    -HermesHome 'D:\PortableData\hermes' `
    -CodexHome 'D:\PortableData\codex' `
    -CursorHome 'D:\PortableData\cursor' `
    -VSCodeUserDir 'D:\PortableData\vscode-user' `
    -SkipCursor `
    -SkipVSCode `
    -PlanOnly
$skipPlan = $skipPlanText | ConvertFrom-Json
Assert-True (-not $skipPlan.configure_cursor -and -not $skipPlan.configure_vscode) 'plan.skip_ide_flags'
Assert-True ($skipPlan.cursor_mcp -eq 'D:\PortableData\cursor\mcp.json') 'plan.skip_still_reports_cursor_path'

$installerContent = Get-Content -Raw -LiteralPath $installer
Assert-True ($installerContent -match 'enable-hermes-ide-mcp\.py') 'installer.ide_mcp_helper'
Assert-True ($installerContent -match 'plugins\\local\\ai-os-hermes-worker') 'installer.cursor_plugin_path'
$ideHelper = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'scripts\enable-hermes-ide-mcp.py')
Assert-True ($ideHelper -match 'hermes-install.lock.json') 'ide.version_from_lock'
Assert-True ($ideHelper -notmatch '1\.6\.2') 'ide.no_hardcoded_plugin_version'
Assert-True ($ideHelper -match 'legacy-rule-preserved') 'ide.preserve_custom_legacy_rule'
Assert-True ($installerContent -notmatch 'Join-Path \$CursorHome ''rules\\hermes-worker\.mdc''') 'installer.no_legacy_cursor_rules'
Assert-True ($installerContent -match 'SkipCursor') 'installer.skip_cursor'
Assert-True ($installerContent -match 'SkipVSCode') 'installer.skip_vscode'
Assert-True ($installerContent -match 'skills opt-in --sync') 'installer.native_skill_sync'
Assert-True ($installerContent -match 'autonomous-ai-agents\\hermes-agent\\SKILL\.md') 'installer.hermes_agent_skill_check'
Assert-True ($installerContent -match 'note-taking\\obsidian\\SKILL\.md') 'installer.obsidian_skill_check'
$configHelperContent = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'scripts\configure-hermes-memory.py')
Assert-True ($configHelperContent -match 'OBSIDIAN_VAULT_PATH') 'config.obsidian_vault_path'

Assert-True ($installerContent -match 'test-hermes-skills-mcp\.py.*--self-test') 'installer.skills_self_test'

$pythonCommand = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCommand) {
    throw 'Python is required for skills offline self-test.'
}
& $pythonCommand.Source (Join-Path $repoRoot 'scripts\tests\test-hermes-skills-mcp.py') --self-test
Assert-True ($LASTEXITCODE -eq 0) 'skills.self_test'

$portableFiles = @(
    'scripts\Install-HermesObsidianMemory.ps1',
    'scripts\Register-HermesProjects.ps1',
    'scripts\hermes-global.ps1',
    'scripts\enable-hermes-codex-mcp.py',
    'scripts\enable-hermes-ide-mcp.py',
    'scripts\seed-hermes-memory.py',
    'scripts\tests\offline_sitecustomize.py',
    '06_Research\pilots\v1.6-hermes\obsidian-vault\GLOBAL_AGENTS_HERMES_WORKER.md'
)
foreach ($relativePath in $portableFiles) {
    $content = Get-Content -Raw -LiteralPath (Join-Path $repoRoot $relativePath)
    Assert-True ($content -notmatch 'C:\\Users\\prinya') "$relativePath.no_user_path"
    Assert-True ($content -notmatch 'F:\\projectAi') "$relativePath.no_project_path"
}

Write-Output "SUMMARY passed=$passed failed=$failed"
if ($failed -gt 0) {
    exit 1
}
exit 0
