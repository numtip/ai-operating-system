$ErrorActionPreference = 'Stop'

$localAppData = [Environment]::GetFolderPath('LocalApplicationData')
$hermesHome = if ([string]::IsNullOrWhiteSpace($env:HERMES_HOME)) {
    Join-Path $localAppData 'hermes'
}
else {
    $env:HERMES_HOME
}
$integrationConfig = Join-Path $hermesHome 'aios-integration.json'

if (-not (Test-Path -LiteralPath $integrationConfig)) {
    Write-Error "AI-OS Hermes integration config not found: $integrationConfig. Run scripts/Install-HermesObsidianMemory.ps1 first."
    exit 1
}

$integration = Get-Content -Raw -LiteralPath $integrationConfig | ConvertFrom-Json
$hermesExe = [string]$integration.hermes_executable
if ([string]::IsNullOrWhiteSpace($hermesExe) -or -not (Test-Path -LiteralPath $hermesExe)) {
    Write-Error "Hermes executable not found: $hermesExe"
    exit 1
}

$env:HERMES_HOME = $hermesHome
& $hermesExe @args
exit $LASTEXITCODE
