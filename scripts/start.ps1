#Requires -Version 5.1
<#
.SYNOPSIS
    Avvia lo stack Docker di C64GameEngine.

.DESCRIPTION
    Produce -> stack di produzione (nginx), http://localhost:3000
    Sviluppo -> stack di sviluppo (vite + hot reload), http://localhost:3001

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts\start.ps1

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts\start.ps1 -Dev
#>
[CmdletBinding()]
param(
    [switch]$Dev,
    [switch]$NoBuild,
    [switch]$Foreground
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

$appPort = if ($env:APP_PORT) { $env:APP_PORT } else { '3000' }
$devPort = if ($env:DEV_PORT) { $env:DEV_PORT } else { '3001' }

$composeArgs = @('-f', $ComposeFile)
if ($Dev) { $composeArgs += @('--profile', 'dev') }

if ($Dev) {
    $container = 'c64gameengine-dev'
    $service = 'dev'
    $url = "http://localhost:$devPort"
    Write-C64Info 'Avvio dello stack di SVILUPPO (vite, hot reload)'
} else {
    $container = 'c64gameengine'
    $service = 'app'
    $url = "http://localhost:$appPort"
    Write-C64Info 'Avvio dello stack di PRODUZIONE (nginx)'
}

$upArgs = @('up', '-d', '--remove-orphans', $service)
if (-not $NoBuild) { $upArgs += '--build' }

Write-C64Info "docker compose $($composeArgs -join ' ') $($upArgs -join ' ')"
try {
    Invoke-C64Compose -Arguments ($composeArgs + $upArgs)
} catch {
    Write-C64Fail $_.Exception.Message
    exit 1
}

if ($Foreground) {
    Write-C64Info 'Log in tempo reale (Ctrl+C per interrompere)'
    Invoke-C64Compose -Arguments ($composeArgs + @('logs', '-f')) | Out-Null
    exit 0
}

Write-C64Info "Attesa del container '$container'..."
if (Wait-C64Container -Name $container -TimeoutSeconds 120) {
    Write-C64Ok "Container '$container' pronto."
} else {
    Write-C64Warn "Il container non risulta pronto: controlla i log con scripts\logs.ps1"
}

Write-Host ''
Write-C64Ok "C64GameEngine e' online: $url"
Write-C64Info 'Log:     scripts\logs.ps1'
Write-C64Info 'Arresto: scripts\stop.ps1'
Write-Host ''
