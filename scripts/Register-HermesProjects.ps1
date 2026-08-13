[CmdletBinding()]
param(
    [string]$ProjectRoot,
    [string]$HermesHome,
    [string]$HermesExe
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = Split-Path -Parent $repoRoot
}
if ([string]::IsNullOrWhiteSpace($HermesHome)) {
    $HermesHome = if ([string]::IsNullOrWhiteSpace($env:HERMES_HOME)) {
        Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'hermes'
    }
    else {
        $env:HERMES_HOME
    }
}
if ([string]::IsNullOrWhiteSpace($HermesExe)) {
    $HermesExe = Join-Path $repoRoot '.runtime\hermes-agent\.venv\Scripts\hermes.exe'
}

if (-not (Test-Path -LiteralPath $HermesExe)) {
    throw "Hermes executable not found: $HermesExe"
}

if (-not (Test-Path -LiteralPath $ProjectRoot)) {
    throw "Project root not found: $ProjectRoot"
}

$env:HERMES_HOME = $HermesHome
$projectRootFull = (Resolve-Path -LiteralPath $ProjectRoot).Path.TrimEnd('\')

$existingOutput = & $HermesExe project list 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "Unable to list Hermes projects: $($existingOutput -join [Environment]::NewLine)"
}

$existingSlugs = @{}
foreach ($line in $existingOutput) {
    if ($line -match '^\s*[\* ]\s*([a-z0-9][a-z0-9-]*)\s+') {
        $existingSlugs[$Matches[1]] = $true
    }
}

$skipDirectoryNames = @(
    '.runtime', '.venv', 'venv', 'node_modules',
    'dist', 'build', '.next', 'coverage', '__pycache__'
)

$repoPaths = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase
)
$pending = [System.Collections.Generic.Stack[string]]::new()
$pending.Push((Resolve-Path -LiteralPath $ProjectRoot).Path)

while ($pending.Count -gt 0) {
    $directory = $pending.Pop()
    if (Test-Path -LiteralPath (Join-Path $directory '.git')) {
        [void]$repoPaths.Add($directory)
    }

    foreach ($child in Get-ChildItem -LiteralPath $directory -Directory -Force -ErrorAction SilentlyContinue) {
        if (
            $child.Name -eq '.git' -or
            $skipDirectoryNames -contains $child.Name -or
            ($child.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
        ) {
            continue
        }
        $pending.Push($child.FullName)
    }
}

$repos = $repoPaths | Sort-Object | ForEach-Object { Get-Item -LiteralPath $_ -Force }

$results = foreach ($repo in $repos) {
    if ($repo.FullName.TrimEnd('\') -eq $projectRootFull) {
        $relativePath = 'projectai-root'
    }
    else {
        $relativePath = $repo.FullName.Substring($projectRootFull.Length).TrimStart('\')
    }
    if ([string]::IsNullOrWhiteSpace($relativePath)) {
        $relativePath = 'projectai-root'
    }
    $slug = $relativePath.ToLowerInvariant() -replace '[^a-z0-9]+', '-'
    $slug = $slug.Trim('-')

    if ($existingSlugs.ContainsKey($slug)) {
        [pscustomobject]@{
            Project = $repo.Name
            Slug = $slug
            Path = $repo.FullName
            Result = 'already-registered'
        }
        continue
    }

    $projectName = if ($relativePath -eq 'projectai-root') { 'projectAi root' } else { $relativePath }
    $output = & $HermesExe project create $projectName $repo.FullName --slug $slug --primary $repo.FullName 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to register $($repo.FullName): $($output -join [Environment]::NewLine)"
    }

    $existingSlugs[$slug] = $true
    [pscustomobject]@{
        Project = $repo.Name
        Slug = $slug
        Path = $repo.FullName
        Result = 'registered'
    }
}

$results
