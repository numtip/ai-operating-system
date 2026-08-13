[CmdletBinding()]
param(
    [string]$ProjectRoot,
    [string]$HermesInstallRoot,
    [string]$HermesHome,
    [string]$CodexHome,
    [string]$LauncherDirectory,
    [string]$PythonExecutable,
    [switch]$InstallObsidian,
    [switch]$OpenObsidian,
    [switch]$SkipCodex,
    [switch]$SkipProjectRegistration,
    [switch]$PlanOnly
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$lockPath = Join-Path $PSScriptRoot 'hermes-install.lock.json'
$lock = Get-Content -Raw -LiteralPath $lockPath | ConvertFrom-Json

$userProfile = [Environment]::GetFolderPath('UserProfile')
$localAppData = [Environment]::GetFolderPath('LocalApplicationData')
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = Split-Path -Parent $repoRoot
}
if ([string]::IsNullOrWhiteSpace($HermesInstallRoot)) {
    $HermesInstallRoot = Join-Path $repoRoot '.runtime\hermes-agent'
}
if ([string]::IsNullOrWhiteSpace($HermesHome)) {
    $HermesHome = Join-Path $localAppData 'hermes'
}
if ([string]::IsNullOrWhiteSpace($CodexHome)) {
    $CodexHome = if ([string]::IsNullOrWhiteSpace($env:CODEX_HOME)) {
        Join-Path $userProfile '.codex'
    }
    else {
        $env:CODEX_HOME
    }
}
if ([string]::IsNullOrWhiteSpace($LauncherDirectory)) {
    $LauncherDirectory = Join-Path $userProfile '.local\bin'
}

$plan = [ordered]@{
    ai_os_release = [string]$lock.ai_os_release
    project_root = [System.IO.Path]::GetFullPath($ProjectRoot)
    hermes_install_root = [System.IO.Path]::GetFullPath($HermesInstallRoot)
    hermes_home = [System.IO.Path]::GetFullPath($HermesHome)
    codex_home = [System.IO.Path]::GetFullPath($CodexHome)
    launcher_directory = [System.IO.Path]::GetFullPath($LauncherDirectory)
    hermes_repository = [string]$lock.hermes.repository
    hermes_tag = [string]$lock.hermes.tag
    hermes_version = [string]$lock.hermes.version
    hermes_commit = [string]$lock.hermes.commit
    install_obsidian = [bool]$InstallObsidian
    open_obsidian = [bool]$OpenObsidian
    configure_codex = -not [bool]$SkipCodex
    register_projects = -not [bool]$SkipProjectRegistration
}

if ($PlanOnly) {
    $plan | ConvertTo-Json -Depth 4
    exit 0
}

if ($env:OS -ne 'Windows_NT') {
    throw 'This release installer currently supports Windows only.'
}
foreach ($requiredPath in @($repoRoot, $PSScriptRoot, $lockPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Required AI-OS path not found: $requiredPath"
    }
}
if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
    throw "Project root not found: $ProjectRoot"
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git is required but was not found on PATH.'
}

if ([string]::IsNullOrWhiteSpace($PythonExecutable)) {
    $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pythonCommand) {
        throw 'Python 3.11, 3.12, or 3.13 is required but python was not found on PATH.'
    }
    $PythonExecutable = $pythonCommand.Source
}
if (-not (Test-Path -LiteralPath $PythonExecutable)) {
    throw "Python executable not found: $PythonExecutable"
}
$pythonVersionText = & $PythonExecutable -c 'import sys; print(sys.version_info.major, sys.version_info.minor, sep=chr(46))'
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to read Python version.'
}
$pythonVersion = [version]$pythonVersionText.Trim()
if ($pythonVersion -lt [version]'3.11' -or $pythonVersion -ge [version]'3.14') {
    throw "Unsupported Python $pythonVersion. Hermes v0.20.0 requires >=3.11,<3.14."
}

$installParent = Split-Path -Parent $HermesInstallRoot
New-Item -ItemType Directory -Path $installParent -Force | Out-Null
if (-not (Test-Path -LiteralPath $HermesInstallRoot)) {
    & git clone --branch $lock.hermes.tag --depth 1 $lock.hermes.repository $HermesInstallRoot
    if ($LASTEXITCODE -ne 0) {
        throw 'Hermes clone failed.'
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $HermesInstallRoot '.git'))) {
    throw "Existing install root is not a Git checkout: $HermesInstallRoot"
}

$installedCommit = (& git -C $HermesInstallRoot rev-parse HEAD).Trim()
$tagCommit = (& git -C $HermesInstallRoot rev-list -n 1 $lock.hermes.tag).Trim()
if ($LASTEXITCODE -ne 0 -or $installedCommit -ne $lock.hermes.commit -or $tagCommit -ne $lock.hermes.commit) {
    throw "Hermes source pin mismatch. Expected $($lock.hermes.commit); HEAD=$installedCommit; tag=$tagCommit"
}

$venvPython = Join-Path $HermesInstallRoot '.venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $venvPython)) {
    & $PythonExecutable -m venv (Join-Path $HermesInstallRoot '.venv')
    if ($LASTEXITCODE -ne 0) {
        throw 'Hermes virtual environment creation failed.'
    }
}
$editableTarget = "$HermesInstallRoot[mcp]"
& $venvPython -m pip install --editable $editableTarget
if ($LASTEXITCODE -ne 0) {
    throw 'Hermes pinned runtime installation failed.'
}

New-Item -ItemType Directory -Path $HermesHome -Force | Out-Null
$env:HERMES_HOME = [System.IO.Path]::GetFullPath($HermesHome)
& $venvPython (Join-Path $PSScriptRoot 'configure-hermes-memory.py') --hermes-home $HermesHome
if ($LASTEXITCODE -ne 0) {
    throw 'Hermes memory configuration failed.'
}

$hermesExe = Join-Path $HermesInstallRoot '.venv\Scripts\hermes.exe'
$integrationPath = Join-Path $HermesHome 'aios-integration.json'
if (Test-Path -LiteralPath $integrationPath) {
    Copy-Item -LiteralPath $integrationPath -Destination "$integrationPath.bak" -Force
}
[ordered]@{
    schema_version = '1.0'
    ai_os_release = [string]$lock.ai_os_release
    ai_os_repo = [System.IO.Path]::GetFullPath($repoRoot)
    projects_root = [System.IO.Path]::GetFullPath($ProjectRoot)
    hermes_executable = [System.IO.Path]::GetFullPath($hermesExe)
    hermes_commit = [string]$lock.hermes.commit
} | ConvertTo-Json | Set-Content -LiteralPath $integrationPath -Encoding UTF8

$obsidianTemplate = Join-Path $repoRoot '06_Research\pilots\v1.6-hermes\obsidian-vault'
$obsidianConfigTarget = Join-Path $HermesHome '.obsidian'
New-Item -ItemType Directory -Path $obsidianConfigTarget -Force | Out-Null
Copy-Item -Path (Join-Path $obsidianTemplate '*.json') -Destination $obsidianConfigTarget -Force
Copy-Item -LiteralPath (Join-Path $obsidianTemplate 'HERMES_MEMORY_VAULT.md') -Destination $HermesHome -Force

New-Item -ItemType Directory -Path $LauncherDirectory -Force | Out-Null
$launcherPath = Join-Path $LauncherDirectory 'hermes.ps1'
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'hermes-global.ps1') -Destination $launcherPath -Force
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$pathEntries = @($userPath -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
if ($pathEntries -notcontains $LauncherDirectory) {
    $newUserPath = (@($pathEntries) + $LauncherDirectory) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
}
if (($env:Path -split ';') -notcontains $LauncherDirectory) {
    $env:Path = "$env:Path;$LauncherDirectory"
}

if (-not $SkipCodex) {
    New-Item -ItemType Directory -Path $CodexHome -Force | Out-Null
    $agentsPath = Join-Path $CodexHome 'AGENTS.md'
    $agentsTemplate = Get-Content -Raw -LiteralPath (Join-Path $obsidianTemplate 'GLOBAL_AGENTS_HERMES_MEMORY.md')
    $startMarker = '<!-- AI-OS HERMES MEMORY START -->'
    $endMarker = '<!-- AI-OS HERMES MEMORY END -->'
    $existingAgents = if (Test-Path -LiteralPath $agentsPath) {
        Get-Content -Raw -LiteralPath $agentsPath
    }
    else {
        ''
    }
    $managedBlock = "$startMarker`r`n$agentsTemplate`r`n$endMarker"
    if ($existingAgents -match [regex]::Escape($startMarker)) {
        $pattern = [regex]::Escape($startMarker) + '[\s\S]*?' + [regex]::Escape($endMarker)
        $newAgents = [regex]::Replace($existingAgents, $pattern, $managedBlock)
    }
    else {
        $newAgents = ($existingAgents.TrimEnd() + "`r`n`r`n" + $managedBlock).TrimStart()
    }
    if (Test-Path -LiteralPath $agentsPath) {
        Copy-Item -LiteralPath $agentsPath -Destination "$agentsPath.bak" -Force
    }
    Set-Content -LiteralPath $agentsPath -Value $newAgents -Encoding UTF8

    & $venvPython (Join-Path $PSScriptRoot 'enable-hermes-codex-mcp.py') `
        --codex-home $CodexHome `
        --hermes-home $HermesHome `
        --memory-server (Join-Path $PSScriptRoot 'hermes-memory-mcp-server.py')
    if ($LASTEXITCODE -ne 0) {
        throw 'Codex MCP configuration failed.'
    }
}

if (-not $SkipProjectRegistration) {
    & (Join-Path $PSScriptRoot 'Register-HermesProjects.ps1') `
        -ProjectRoot $ProjectRoot `
        -HermesHome $HermesHome `
        -HermesExe $hermesExe
}

& $venvPython (Join-Path $PSScriptRoot 'seed-hermes-memory.py') `
    --projects-root $ProjectRoot `
    --hermes-home $HermesHome
if ($LASTEXITCODE -ne 0) {
    throw 'Hermes memory seed failed.'
}

if (-not $SkipCodex) {
    & $venvPython (Join-Path $PSScriptRoot 'tests\test-hermes-memory-mcp.py') `
        --python $venvPython `
        --server (Join-Path $PSScriptRoot 'hermes-memory-mcp-server.py') `
        --hermes-home $HermesHome
    if ($LASTEXITCODE -ne 0) {
        throw 'Hermes MCP protocol verification failed.'
    }
}

$obsidianExe = Join-Path $localAppData 'Programs\Obsidian\Obsidian.exe'
if (-not (Test-Path -LiteralPath $obsidianExe) -and $InstallObsidian) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'Obsidian is missing and winget is not available.'
    }
    & winget install --id Obsidian.Obsidian --exact --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        throw 'Obsidian installation failed.'
    }
}
if ($OpenObsidian) {
    if (-not (Test-Path -LiteralPath $obsidianExe)) {
        throw 'Obsidian is not installed. Re-run with -InstallObsidian.'
    }
    Start-Process -FilePath $obsidianExe -ArgumentList ('"' + $HermesHome + '"') | Out-Null
}

& $hermesExe --version
if ($LASTEXITCODE -ne 0) {
    throw 'Final Hermes version check failed.'
}

[pscustomobject]@{
    Status = 'PASS'
    AIOSRelease = [string]$lock.ai_os_release
    HermesVersion = [string]$lock.hermes.version
    HermesCommit = $installedCommit
    HermesHome = [System.IO.Path]::GetFullPath($HermesHome)
    ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
    Launcher = [System.IO.Path]::GetFullPath($launcherPath)
    CodexRestartRequired = -not [bool]$SkipCodex
    ObsidianVault = [System.IO.Path]::GetFullPath($HermesHome)
}
