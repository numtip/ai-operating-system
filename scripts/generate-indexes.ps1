<#
.SYNOPSIS
  Regenerates lightweight JSON indexes under 12_Indexes/ from repo metadata.
.DESCRIPTION
  Stdlib PowerShell only. Scans canonical knowledge docs, 01_Projects, 04_ADR,
  and 08_Skills. Writes path/title references only (no document bodies).
  Preserves schema_version 1.0 and optional note fields where applicable.
  Run from repo root:
    pwsh -File scripts/generate-indexes.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File scripts/generate-indexes.ps1
  Exit 0 on success, 1 on failure.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = Resolve-Path (Join-Path $PSScriptRoot '..')
$IndexDir = Join-Path $Root '12_Indexes'
$SchemaVersion = '1.0'

function ConvertTo-RepoRelativePath {
    param([Parameter(Mandatory)][string]$FullPath)
    $full = [System.IO.Path]::GetFullPath($FullPath)
    $rootFull = [System.IO.Path]::GetFullPath($Root)
    if (-not $full.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path outside repo: $FullPath"
    }
    $rel = $full.Substring($rootFull.Length).TrimStart('\', '/')
    return ($rel -replace '\\', '/')
}

function New-IndexEntry {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][string]$Path,
        [string[]]$Tags = @()
    )
    [ordered]@{
        id    = $Id
        title = $Title
        path  = ($Path -replace '\\', '/')
        tags  = @($Tags)
    }
}

function Get-MarkdownTitle {
    param([Parameter(Mandatory)][string]$FullPath)
    if (-not (Test-Path -LiteralPath $FullPath -PathType Leaf)) { return $null }
    $lines = Get-Content -LiteralPath $FullPath -TotalCount 20 -ErrorAction SilentlyContinue
    foreach ($line in $lines) {
        if ($line -match '^#\s+(.+)$') {
            $t = $Matches[1].Trim()
            $t = $t -replace '^ADR-\d+:\s*', ''
            return $t
        }
    }
    return [System.IO.Path]::GetFileNameWithoutExtension($FullPath)
}

function Write-IndexJson {
    param(
        [Parameter(Mandatory)][string]$FileName,
        [Parameter(Mandatory)]$Document
    )
    if (-not (Test-Path -LiteralPath $IndexDir -PathType Container)) {
        New-Item -ItemType Directory -Path $IndexDir -Force | Out-Null
    }
    $outPath = Join-Path $IndexDir $FileName
    $json = $Document | ConvertTo-Json -Depth 8
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($outPath, $json + "`n", $utf8)
    Write-Host "Wrote 12_Indexes/$FileName"
}

try {
    Write-Host "Generating indexes under: $Root"
    Write-Host ""

    # --- knowledge_index.json (canonical seed set; refresh titles from disk) ---
    $knowledgeSeeds = @(
        @{ Id = 'readme'; Title = 'README'; Rel = 'README.md'; Tags = @('canonical', 'entrypoint') }
        @{ Id = 'manifesto'; Title = 'AI OS Manifesto'; Rel = 'AI_OS_MANIFESTO.md'; Tags = @('canonical', 'manifesto') }
        @{ Id = 'context-engine'; Title = 'Context Engine'; Rel = '03_Architecture/CONTEXT_ENGINE.md'; Tags = @('canonical', 'architecture', 'context') }
        @{ Id = 'architecture-overview'; Title = 'Architecture Overview'; Rel = '03_Architecture/ARCHITECTURE_OVERVIEW.md'; Tags = @('canonical', 'architecture') }
        @{ Id = 'glossary'; Title = 'Glossary'; Rel = '02_Knowledge/GLOSSARY.md'; Tags = @('canonical', 'knowledge') }
        @{ Id = 'operating-rules'; Title = 'Operating Rules'; Rel = '07_Memory/OPERATING_RULES.md'; Tags = @('canonical', 'memory', 'governance') }
        @{ Id = 'system-memory'; Title = 'System Memory'; Rel = '07_Memory/SYSTEM_MEMORY.md'; Tags = @('canonical', 'memory') }
        @{ Id = 'current-state'; Title = 'Current State'; Rel = '07_Memory/CURRENT_STATE.md'; Tags = @('canonical', 'memory', 'state') }
        @{ Id = 'home'; Title = 'Home'; Rel = '00_Dashboard/HOME.md'; Tags = @('canonical', 'dashboard') }
        @{ Id = 'quickstart'; Title = 'Quickstart'; Rel = '00_Dashboard/QUICKSTART.md'; Tags = @('canonical', 'dashboard', 'onboarding') }
    )

    $knowledgeEntries = @()
    foreach ($seed in $knowledgeSeeds) {
        $full = Join-Path $Root ($seed.Rel -replace '/', [IO.Path]::DirectorySeparatorChar)
        $title = $seed.Title
        if (Test-Path -LiteralPath $full -PathType Leaf) {
            $diskTitle = Get-MarkdownTitle -FullPath $full
            if ($diskTitle) { $title = $diskTitle }
        }
        $knowledgeEntries += ,(New-IndexEntry -Id $seed.Id -Title $title -Path $seed.Rel -Tags $seed.Tags)
    }
    Write-IndexJson -FileName 'knowledge_index.json' -Document ([ordered]@{
            schema_version = $SchemaVersion
            entries        = $knowledgeEntries
        })

    # --- project_index.json ---
    $projectsRoot = Join-Path $Root '01_Projects'
    $projectEntries = @()
    if (Test-Path -LiteralPath $projectsRoot -PathType Container) {
        Get-ChildItem -LiteralPath $projectsRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch '^\.' } |
            ForEach-Object {
                $readme = Join-Path $_.FullName 'README.md'
                $title = $_.Name
                if (Test-Path -LiteralPath $readme -PathType Leaf) {
                    $t = Get-MarkdownTitle -FullPath $readme
                    if ($t) { $title = $t }
                }
                $rel = ConvertTo-RepoRelativePath -FullPath $_.FullName
                if (-not $rel.EndsWith('/')) { $rel = "$rel/" }
                $id = ($_.Name.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
                if (-not $id) { $id = 'project' }
                $projectEntries += ,(New-IndexEntry -Id "project-$id" -Title $title -Path $rel -Tags @('project'))
            }
    }
    $projectDoc = [ordered]@{
        schema_version = $SchemaVersion
        entries        = $projectEntries
    }
    if ($projectEntries.Count -eq 0) {
        $projectDoc['note'] = 'No project folders under 01_Projects yet (placeholder .gitkeep only). Entries populate when projects are added.'
    }
    Write-IndexJson -FileName 'project_index.json' -Document $projectDoc

    # --- adr_index.json (ADR-NNNN-*.md, exclude TEMPLATE) ---
    $adrRoot = Join-Path $Root '04_ADR'
    $adrEntries = @()
    if (Test-Path -LiteralPath $adrRoot -PathType Container) {
        Get-ChildItem -LiteralPath $adrRoot -File -Filter 'ADR-*.md' -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^ADR-\d{4}-' -and $_.Name -notmatch 'TEMPLATE' } |
            Sort-Object Name |
            ForEach-Object {
                if ($_.Name -notmatch '^ADR-(\d{4})-') { return }
                $num = $Matches[1]
                $title = Get-MarkdownTitle -FullPath $_.FullName
                if (-not $title) { $title = $_.BaseName }
                $rel = ConvertTo-RepoRelativePath -FullPath $_.FullName
                $adrEntries += ,(New-IndexEntry -Id "adr-$num" -Title $title -Path $rel -Tags @('adr'))
            }
    }
    Write-IndexJson -FileName 'adr_index.json' -Document ([ordered]@{
            schema_version = $SchemaVersion
            entries        = $adrEntries
        })

    # --- skill_index.json ---
    $skillsRoot = Join-Path $Root '08_Skills'
    $skillEntries = @()
    if (Test-Path -LiteralPath $skillsRoot -PathType Container) {
        $skillDirs = @(Get-ChildItem -LiteralPath $skillsRoot -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -notmatch '^\.' })
        $skillFiles = @(Get-ChildItem -LiteralPath $skillsRoot -File -Filter 'SKILL.md' -Recurse -ErrorAction SilentlyContinue)
        if ($skillDirs.Count -eq 0 -and $skillFiles.Count -eq 0) {
            $skillEntries += ,(New-IndexEntry -Id 'skills-root' -Title 'Skills (placeholder)' -Path '08_Skills/' -Tags @('skills', 'placeholder'))
        }
        else {
            foreach ($d in $skillDirs) {
                $skillMd = Join-Path $d.FullName 'SKILL.md'
                $title = $d.Name
                if (Test-Path -LiteralPath $skillMd -PathType Leaf) {
                    $t = Get-MarkdownTitle -FullPath $skillMd
                    if ($t) { $title = $t }
                    $rel = ConvertTo-RepoRelativePath -FullPath $skillMd
                }
                else {
                    $rel = ConvertTo-RepoRelativePath -FullPath $d.FullName
                    if (-not $rel.EndsWith('/')) { $rel = "$rel/" }
                }
                $id = ($d.Name.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
                $skillEntries += ,(New-IndexEntry -Id "skill-$id" -Title $title -Path $rel -Tags @('skills'))
            }
            foreach ($f in $skillFiles) {
                $parent = $f.Directory.Name
                if ($skillDirs | Where-Object { $_.Name -eq $parent }) { continue }
                $title = Get-MarkdownTitle -FullPath $f.FullName
                if (-not $title) { $title = $f.Directory.Name }
                $rel = ConvertTo-RepoRelativePath -FullPath $f.FullName
                $id = ($f.Directory.Name.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
                $skillEntries += ,(New-IndexEntry -Id "skill-$id" -Title $title -Path $rel -Tags @('skills'))
            }
        }
    }
    $skillDoc = [ordered]@{
        schema_version = $SchemaVersion
        entries        = $skillEntries
    }
    if ($skillEntries.Count -eq 1 -and $skillEntries[0].id -eq 'skills-root') {
        $skillDoc['note'] = 'Placeholder until skills are authored under 08_Skills/. Points at skills root only.'
    }
    Write-IndexJson -FileName 'skill_index.json' -Document $skillDoc

    Write-Host ""
    Write-Host "RESULT: PASS"
    exit 0
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "RESULT: FAIL"
    exit 1
}
