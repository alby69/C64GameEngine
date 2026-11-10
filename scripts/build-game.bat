@echo off
setlocal enabledelayedexpansion
rem ============================================================================
rem  C64 GAME ENGINE - compilazione del gioco (Windows)
rem
rem  Uso:  scripts\build-game.bat [-docker] [-test] [-game <nome>]
rem
rem  Usa l'assembler ACME se e' nel PATH, altrimenti compila dentro Docker
rem  (nessuna installazione richiesta sull'host).
rem ============================================================================

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%.."

set "GAME=space-invaders"
set "MODE=auto"
set "RUN_TEST=0"

rem ---------------------------------------------------------------------------
rem Argomenti
rem ---------------------------------------------------------------------------
:parse_args
if "%~1"=="" goto args_done
if /i "%~1"=="-docker"  ( set "MODE=docker" & shift & goto parse_args )
if /i "%~1"=="--docker" ( set "MODE=docker" & shift & goto parse_args )
if /i "%~1"=="-test"    ( set "RUN_TEST=1" & shift & goto parse_args )
if /i "%~1"=="--test"   ( set "RUN_TEST=1" & shift & goto parse_args )
if /i "%~1"=="-game"    ( set "GAME=%~2" & shift & shift & goto parse_args )
if /i "%~1"=="--game"   ( set "GAME=%~2" & shift & shift & goto parse_args )
if /i "%~1"=="-h"       goto usage
if /i "%~1"=="--help"   goto usage
echo [FAIL] Opzione sconosciuta: %1
goto usage_error

:args_done

rem ---------------------------------------------------------------------------
rem Nome del file .prg (il trattino diventa underscore)
rem ---------------------------------------------------------------------------
set "GAME_FILE=%GAME:-=_%"
set "TARGET=games\%GAME%\%GAME_FILE%.prg"

rem ---------------------------------------------------------------------------
rem ACME nel PATH oppure Docker
rem ---------------------------------------------------------------------------
set "USE_DOCKER=0"
if /i "%MODE%"=="docker" (
    set "USE_DOCKER=1"
) else (
    where acme >nul 2>&1
    if errorlevel 1 (
        echo [WARN] ACME non trovato nel PATH: uso la compilazione dentro Docker.
        set "USE_DOCKER=1"
    )
)

if "%USE_DOCKER%"=="1" (
    where docker >nul 2>&1
    if errorlevel 1 (
        echo [FAIL] Docker non e' installato: https://docs.docker.com/get-docker/
        exit /b 1
    )
    docker info >nul 2>&1
    if errorlevel 1 (
        echo [FAIL] Docker daemon non raggiungibile. Avvia Docker Desktop e riprova.
        exit /b 1
    )
    set "COMPOSE="
    docker compose version >nul 2>&1
    if not errorlevel 1 set "COMPOSE=docker compose"
    if not defined COMPOSE (
        where docker-compose >nul 2>&1
        if not errorlevel 1 set "COMPOSE=docker-compose"
    )
    if not defined COMPOSE (
        echo [FAIL] Docker Compose non trovato.
        exit /b 1
    )
    echo [INFO] Compilazione di '%GAME%' dentro Docker ^(ACME^)
    !COMPOSE! -f "%CD%\docker-compose.yml" --profile build run --rm assembler
    if errorlevel 1 (
        echo [FAIL] La compilazione Docker e' fallita.
        exit /b 1
    )
) else (
    echo [INFO] Compilazione di '%GAME%' con ACME
    acme -f cbm -o "%TARGET%" -l symbols.txt -I engine -I "games\%GAME%" "games\%GAME%\si_main.asm"
    if errorlevel 1 (
        echo [FAIL] ACME ha restituito il codice di errore %ERRORLEVEL%.
        exit /b 1
    )
)

echo [ OK ] Compilato: %TARGET%

rem ---------------------------------------------------------------------------
rem Test automatico (emulatore 6502)
rem ---------------------------------------------------------------------------
if "%RUN_TEST%"=="1" (
    where python >nul 2>&1
    if errorlevel 1 (
        echo [WARN] python non trovato: test saltati.
        exit /b 0
    )
    echo [INFO] Esecuzione dei test automatici
    python tools\c64test.py "%TARGET%" symbols.txt
    if errorlevel 1 (
        echo [FAIL] I test automatici sono falliti.
        exit /b 1
    )
)

exit /b 0

rem ---------------------------------------------------------------------------
rem Usage
rem ---------------------------------------------------------------------------
:usage
echo Usage: scripts\build-game.bat [-docker] [-test] [-game ^<nome^>]
echo.
echo   -docker     compila sempre dentro Docker
echo   -test       esegue anche i test automatici
echo   -game nome  gioco da compilare ^(default: space-invaders^)
exit /b 0

:usage_error
echo.
echo Per l'elenco delle opzioni: scripts\build-game.bat --help
exit /b 1
