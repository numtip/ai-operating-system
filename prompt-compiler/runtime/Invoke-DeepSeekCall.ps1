<#
.SYNOPSIS
  Stage 2A -- single bounded DeepSeek chat call (child process).
.DESCRIPTION
  Runs ONE chat/completions call against the DeepSeek API using the key loaded
  from the external secret file (%LOCALAPPDATA%\AI-OS\stage2a.env). This script is
  spawned by Invoke-Stage2aLiveRun.ps1; it is the ONLY place the key is read.

  Security contract:
    - Loads the key inside this child process only (never in the parent).
    - Sets DEEPSEEK_API_KEY env in child scope, uses it for the Authorization
      header, then removes it. Environment is never logged.
    - Outputs ONLY sanitized JSON (ok/model/usage/latency/status_code).
      On error the response body and header are suppressed.
    - Never writes the key or the prompt to any file or log.
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File Invoke-DeepSeekCall.ps1 `
    -SecretPath "$env:LOCALAPPDATA\AI-OS\stage2a.env" `
    -Prompt "Reply with the single token OK." -Model deepseek-v4-flash -MaxTokens 2000
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SecretPath,
    [Parameter(Mandatory)][AllowEmptyString()][string]$Prompt,
    [Parameter(Mandatory)][string]$Model,
    [int]$MaxTokens = 2000,
    [string]$BaseUrl = 'https://api.deepseek.com'
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

. (Join-Path $PSScriptRoot 'Secret-Loader.ps1')

function Out-CallResult {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Json)
    Write-Output $Json
    exit 0
}

$map = Get-ExternalSecretEnv -Path $SecretPath
if (-not $map.ContainsKey('DEEPSEEK_API_KEY') -or [string]::IsNullOrWhiteSpace([string]$map['DEEPSEEK_API_KEY'])) {
    Out-CallResult -Json ([ordered]@{ ok = $false; error = 'DEEPSEEK_API_KEY missing or empty' } | ConvertTo-Json -Compress)
}
$key = [string]$map['DEEPSEEK_API_KEY']
$env:DEEPSEEK_API_KEY = $key      # child-process scope only; never logged

$uri = "$BaseUrl/chat/completions"
$body = [ordered]@{
    model      = $Model
    messages   = @(@{ role = 'user'; content = $Prompt })
    max_tokens = $MaxTokens
    stream     = $false
} | ConvertTo-Json -Depth 5

$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $r = Invoke-RestMethod -Uri $uri -Method Post -ContentType 'application/json' `
        -Headers @{ Authorization = ('Bearer ' + $key) } -Body $body -TimeoutSec 120
    $sw.Stop()

    # OpenAI-compatible usage: prompt_tokens/completion_tokens/total_tokens
    $cacheRead = 0L
    if ($r.usage.PSObject.Properties.Name -contains 'prompt_cache_hit_tokens') {
        $cacheRead = [long]$r.usage.prompt_cache_hit_tokens
    }
    $result = [ordered]@{
        ok               = $true
        model            = [string]$r.model
        api_calls        = 1
        latency_seconds  = [Math]::Round($sw.Elapsed.TotalSeconds, 1)
        usage            = [ordered]@{
            input_tokens     = [long]$r.usage.prompt_tokens
            output_tokens    = [long]$r.usage.completion_tokens
            cache_read_tokens = $cacheRead
            total_tokens     = [long]$r.usage.total_tokens
        }
    }
    Out-CallResult -Json ($result | ConvertTo-Json -Compress)
}
catch {
    $sw.Stop()
    $code = $null
    if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
    Out-CallResult -Json ([ordered]@{
        ok              = $false
        status_code     = $code
        latency_seconds = [Math]::Round($sw.Elapsed.TotalSeconds, 1)
        error           = 'request failed (detail suppressed)'
    } | ConvertTo-Json -Compress)
}
finally {
    Remove-Item Env:DEEPSEEK_API_KEY -ErrorAction SilentlyContinue
    $key = $null
    $map = $null
}
