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
Assert-True ($lock.ai_os_release -eq 'v1.6.0-alpha.1') 'lock.ai_os_release'
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
Assert-True ($plan.launcher_directory -eq 'D:\PortableBin') 'plan.launcher_directory'
Assert-True ($plan.hermes_commit -eq $lock.hermes.commit) 'plan.pin_matches_lock'
Assert-True ($plan.install_obsidian -and $plan.open_obsidian) 'plan.obsidian_flags'
Assert-True ($plan.seed_bundled_skills) 'plan.bundled_skills_default_on'

$installerContent = Get-Content -Raw -LiteralPath $installer
Assert-True ($installerContent -match 'skills opt-in --sync') 'installer.native_skill_sync'
Assert-True ($installerContent -match 'autonomous-ai-agents\\hermes-agent\\SKILL\.md') 'installer.hermes_agent_skill_check'
Assert-True ($installerContent -match 'note-taking\\obsidian\\SKILL\.md') 'installer.obsidian_skill_check'
$configHelperContent = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'scripts\configure-hermes-memory.py')
Assert-True ($configHelperContent -match 'OBSIDIAN_VAULT_PATH') 'config.obsidian_vault_path'

$portableFiles = @(
    'scripts\Install-HermesObsidianMemory.ps1',
    'scripts\Register-HermesProjects.ps1',
    'scripts\hermes-global.ps1',
    'scripts\enable-hermes-codex-mcp.py',
    'scripts\seed-hermes-memory.py'
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
