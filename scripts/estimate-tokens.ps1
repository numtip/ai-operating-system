<#
.SYNOPSIS
  Estimate tokens for listed files (Method A: ceil(chars/4)).
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts/estimate-tokens.ps1 -Paths README.md,AI_OS_MANIFESTO.md
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$Paths
)

$ErrorActionPreference = 'Stop'
$Root = Resolve-Path (Join-Path $PSScriptRoot '..')
# Windows PowerShell -File may pass a single comma-joined string
$resolvedPaths = @()
foreach ($p in $Paths) {
    foreach ($part in ($p -split ',')) {
        $t = $part.Trim()
        if ($t) { $resolvedPaths += $t }
    }
}
$Paths = $resolvedPaths
$totalChars = 0L
$totalTokens = 0L
$n = 0

foreach ($p in $Paths) {
    $full = if ([IO.Path]::IsPathRooted($p)) { $p } else { Join-Path $Root ($p -replace '/', '\') }
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        Write-Host "MISS  $p"
        continue
    }
    $text = [IO.File]::ReadAllText($full)
    $chars = $text.Length
    $tok = [int][Math]::Ceiling($chars / 4.0)
    Write-Host ("FILE  {0}  chars={1}  tokens_est={2}" -f $p, $chars, $tok)
    $totalChars += $chars
    $totalTokens += $tok
    $n++
}

Write-Host ("TOTAL files={0} chars={1} tokens_est={2} method=chars/4" -f $n, $totalChars, $totalTokens)
exit 0
