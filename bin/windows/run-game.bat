@echo off
rem C64 GAME ENGINE - gioca al gioco nel simulatore VICE (Windows)
rem Auto-detects and runs the game
rem ============================================================================

rem Determine project root
for %%A in ("%~dp0..") do set "PROJECT_ROOT=%%~fA"

setlocal enabledelayedexpansion

set "GAME=space-invaders"
set "EMULATOR="

rem ----- Argomenti -----
:parse_args
if "%~1"=="" goto args_done
if /i "%~1"=="-game"        ( set "GAME=%~2" & shift & shift & goto parse_args )
if /i "%~1"=="--game"       ( set "GAME=%~2" & shift & shift & goto parse_args )
if /i "%~1"=="-emulatore"   ( set "EMULATOR=%~2" & shift & shift & goto parse_args )
if /i "%~1"=="--emulator"   ( set "EMULATOR=%~2" & shift & shift & goto parse_args )
if /i "%~1"=="-h"           goto usage
if /i "%~1"=="--help"       goto usage
echo [FAIL] Opzione sconosciuta: %1
goto usage_error
goto args_done

:args_done

rem ----- Nome file del gioco -----
set "GAME_FILE=%GAME:-=_%"
set "TARGET=games\%GAME%\%GAME_FILE%.prg"

rem ----- 1. Compila il gioco se il .prg non esiste -----
if not exist "%TARGET%" (
    echo [INFO] Compilo '%GAME%' prima di avviarlo...
    call "%SCRIPT_DIR%..\bin\windows\build-game.bat" -game "%GAME%"
    if errorlevel 1 (
        echo [FAIL] Compilazione fallita.
        exit /b 1
    )
)

if not exist "%TARGET%" (
    echo [FAIL] File non trovato: %TARGET%
    exit /b 1
)

rem ----- 2. Cerca il simulatore VICE -----
if not defined EMULATOR (
    for %%e in (x64.exe x64sc.exe x64 x64sc vice.exe vice) do (
        if not defined EMULATOR (
            where %%e >nul 2>&1 && set "EMULATOR=%%e"
        )
    )
)

if not defined EMULATOR (
    if exist "%ProgramFiles%\vice\x64.exe"    set "EMULATOR=%ProgramFiles%\vice\x64.exe"
    if exist "%ProgramFiles(x86)%\vice\x64.exe" set "EMULATOR=%ProgramFiles(x86)%\vice\x64.exe"
)

if not defined EMULATOR (
    echo.
    echo [FAIL] VICE non trovato.
    echo.
    echo   Installalo da https://vice-emu.org/download.html
    echo   oppure apri il file .prg con un qualsiasi emulatore C64:
    echo.
    echo     %CD%\%TARGET%
    echo.
    echo   Emulatori alternativi: CCS64, Micro64, C64 Online, RetroArch.
    exit /b 1
)

rem ----- 3. Avvia il gioco -----
echo [INFO] Avvio di '%GAME%' con !EMULATOR!
echo [INFO] Per uscire dal simulatore: Ctrl+C (o chiudi la finestra)
echo.
!EMULATOR! -autostartprgmode 1 "%CD%\%TARGET%"
exit /b %ERRORLEVEL%

rem ----- Usage -----
:usage
echo Usage: run-game.bat [-game ^<nome^>] [-emulatore ^<percorso^>]
echo.
echo   -game nome        gioco da avviare ^(default: space-invaders^)
echo   -emulatore path   percorso dell'eseguibile di VICE
exit /b 0

:usage_error
echo.
echo Per l'elenco delle opzioni: run-game.bat --help
exit /b 1