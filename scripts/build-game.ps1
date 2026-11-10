#Requires -Version 5.1
<#
.SYNOPSIS
    Compila il gioco in Assembly 6502 per il Commodore 64.

.DESCRIPTION
    Usa l'assembler ACME se e' disponibile nel PATH, altrimenti compila
    dentro Docker (nessuna installazione richiesta sull'host).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts\build-game.ps1

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts\build-game.ps1 -Docker -Test
#>
[CmdletBinding()]
param(
    [string]$Game = 'space-invaders',
    [switch]$Docker,
    [switch]$Test
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$GameFile = $Game -replace '-', '_'
$target = "games/$Game/$GameFile.prg"

function Invoke-DockerBuild {
    Write-C64Info "Compilazione di '$Game' dentro Docker (ACME)"
    $compose = Get-C64ComposeCommand
    $args = @($compose) + @('--profile', 'build', 'run', '--rm', 'assembler')
    & $args[0] @($args[1..($args.Count - 1)])
    if ($LASTEXITCODE -ne 0) { throw "La compilazione Docker e' fallita." }
}

if ($Docker -or -not (Get-Command acme -ErrorAction SilentlyContinue)) {
    if (-not $Docker) {
        Write-C64Warn "ACME non trovato nel PATH: uso la compilazione dentro Docker."
    }
    try { Test-C64Docker } catch { Write-C64Fail $_.Exception.Message; exit 1 }
    Invoke-DockerBuild
} else {
    Write-C64Info "Compilazione di '$Game' con ACME"
    & acme -f cbm -o $target -l symbols.txt -I engine -I "games/$Game" "games/$Game/si_main.asm"
    if ($LASTEXITCODE -ne 0) { throw "ACME ha restituito il codice $LASTEXITCODE." }
}

Write-C64Ok "Compilato: $target"

if ($Test) {
    if (Get-Command python -ErrorAction SilentlyContinue) {
        Write-C64Info 'Esecuzione dei test automatici'
        & python tools/c64test.py $target symbols.txt
        if ($LASTEXITCODE -ne 0) { throw "I test automatici sono falliti." }
    } else {
        Write-C64Warn 'python non trovato: test saltati.'
    }
}
