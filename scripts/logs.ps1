#Requires -Version 5.1
<#
.SYNOPSIS
    Mostra i log dello stack Docker di C64GameEngine.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts\logs.ps1 -Dev
#>
[CmdletBinding()]
param(
    [switch]$Dev
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ComposeFile = Join-Path $ProjectRoot 'docker-compose.yml'

Set-Location $ProjectRoot
Import-C64EnvFile -Path (Join-Path $ProjectRoot '.env')

try {
    Test-C64Docker
} catch {
    Write-C64Fail $_.Exception.Message
    exit 1
}

$composeArgs = @('-f', $ComposeFile, '--profile', 'dev')
$service = if ($Dev) { 'dev' } else { 'app' }

Invoke-C64Compose -Arguments ($composeArgs + @('logs', '-f', $service)) | Out-Null
