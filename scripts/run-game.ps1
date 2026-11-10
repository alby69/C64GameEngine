#Requires -Version 5.1
<#
.SYNOPSIS
    Gioca al gioco nel simulatore VICE (Windows).

.DESCRIPTION
    Compila il gioco se serve e lo avvia dentro VICE.
    Se VICE non e' installato viene stampato il link per scaricarlo.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts\run-game.ps1

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts\run-game.ps1 -Game hello
#>
[CmdletBinding()]
param(
    [string]$Game = 'space-invaders',
    [string]$Emulator = ''
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$GameFile = $Game -replace '-', '_'
$target = "games/$Game/$GameFile.prg"

# ---------------------------------------------------------------------------
# 1. Compila il gioco se il .prg non esiste
# ---------------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $target)) {
    Write-C64Info "Compilo '$Game' prima di avviarlo..."
    & (Join-Path $PSScriptRoot 'build-game.ps1') -Game $Game
    if ($LASTEXITCODE -ne 0) { throw "Compilazione fallita." }
}

if (-not (Test-Path -LiteralPath $target)) {
    Write-C64Fail "File non trovato: $target"
    exit 1
}

# ---------------------------------------------------------------------------
# 2. Cerca il simulatore VICE
# ---------------------------------------------------------------------------
if (-not $Emulator) {
    foreach ($candidate in @('x64.exe', 'x64sc.exe', 'x64', 'x64sc')) {
        $found = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($found) { $Emulator = $found.Source; break }
    }
}

if (-not $Emulator) {
    foreach ($dir in @("$env:ProgramFiles\vice", "${env:ProgramFiles(x86)}\vice")) {
        $exe = Join-Path $dir 'x64.exe'
        if (Test-Path -LiteralPath $exe) { $Emulator = $exe; break }
    }
}

if (-not $Emulator) {
    Write-Host ''
    Write-C64Fail 'VICE non trovato.'
    Write-Host ''
    Write-Host '  Installalo da https://vice-emu.org/download.html'
    Write-Host '  oppure apri il file .prg con un qualsiasi emulatore C64:'
    Write-Host ''
    Write-Host "    $(Join-Path $ProjectRoot $target)"
    Write-Host ''
    Write-Host '  Emulatori alternativi: CCS64, Micro64, C64 Online, RetroArch.'
    exit 1
}

# ---------------------------------------------------------------------------
# 3. Avvia il gioco
# ---------------------------------------------------------------------------
Write-C64Info "Avvio di '$Game' con $Emulator"
Write-C64Info 'Per uscire dal simulatore: Ctrl+C (o chiudi la finestra)'
Write-Host ''
& $Emulator -autostartprgmode 1 (Join-Path $ProjectRoot $target)
exit $LASTEXITCODE
