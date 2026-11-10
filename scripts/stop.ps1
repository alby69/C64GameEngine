#Requires -Version 5.1
<#
.SYNOPSIS
    Arresta lo stack Docker di C64GameEngine.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts\stop.ps1

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts\stop.ps1 -Dev
#>
[CmdletBinding()]
param(
    [switch]$Dev,
    [switch]$Images,
    [switch]$Volumes
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

if ($Dev) {
    Write-C64Info 'Arresto dello stack di SVILUPPO'
    $downArgs = @('rm', '-s', '-f', 'dev')
} else {
    Write-C64Info 'Arresto di tutti gli stack Docker'
    $downArgs = @('down', '--remove-orphans')
}

if ($Images)  { $downArgs += '--rmi' ; $downArgs += 'local' }
if ($Volumes) { $downArgs += '--volumes' }

try {
    Invoke-C64Compose -Arguments ($composeArgs + $downArgs)
} catch {
    Write-C64Fail $_.Exception.Message
    exit 1
}

Write-C64Ok 'Stack Docker arrestato.'
