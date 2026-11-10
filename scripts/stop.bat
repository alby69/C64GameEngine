@echo off
setlocal enabledelayedexpansion
rem ============================================================================
rem  C64 GAME ENGINE - arresto dello stack Docker (Windows)
rem
rem  Uso:  scripts\stop.bat [-dev] [-images] [-volumes]
rem ============================================================================

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%.."

set "ONLY_DEV=0"
set "REMOVE_IMAGES=0"
set "REMOVE_VOLUMES=0"

rem ---------------------------------------------------------------------------
rem Argomenti
rem ---------------------------------------------------------------------------
:parse_args
if "%~1"=="" goto args_done
if /i "%~1"=="-dev"       ( set "ONLY_DEV=1" & shift & goto parse_args )
if /i "%~1"=="--dev"      ( set "ONLY_DEV=1" & shift & goto parse_args )
if /i "%~1"=="-images"    ( set "REMOVE_IMAGES=1" & shift & goto parse_args )
if /i "%~1"=="--images"   ( set "REMOVE_IMAGES=1" & shift & goto parse_args )
if /i "%~1"=="-volumes"   ( set "REMOVE_VOLUMES=1" & shift & goto parse_args )
if /i "%~1"=="--volumes"  ( set "REMOVE_VOLUMES=1" & shift & goto parse_args )
if /i "%~1"=="-h"         goto usage
if /i "%~1"=="--help"     goto usage
echo [FAIL] Opzione sconosciuta: %1
goto usage_error

:args_done

rem ---------------------------------------------------------------------------
rem Controlli preliminari
rem ---------------------------------------------------------------------------
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

set "COMPOSE_FILE=%CD%\docker-compose.yml"

if "%ONLY_DEV%"=="1" (
    echo [INFO] Arresto dello stack di SVILUPPO
    set "DOWN_ARGS=rm -s -f dev"
) else (
    echo [INFO] Arresto di tutti gli stack Docker
    set "DOWN_ARGS=down --remove-orphans"
)

if "%REMOVE_IMAGES%"=="1"  set "DOWN_ARGS=!DOWN_ARGS! --rmi local"
if "%REMOVE_VOLUMES%"=="1" set "DOWN_ARGS=!DOWN_ARGS! --volumes"

!COMPOSE! -f "!COMPOSE_FILE!" --profile dev !DOWN_ARGS!
if errorlevel 1 (
    echo [FAIL] docker compose ha fallito.
    exit /b 1
)

echo [ OK ] Stack Docker arrestato.
exit /b 0

rem ---------------------------------------------------------------------------
rem Usage
rem ---------------------------------------------------------------------------
:usage
echo Usage: scripts\stop.bat [-dev] [-images] [-volumes]
echo.
echo   -dev       arresta solo lo stack di sviluppo
echo   -images    rimuove anche le immagini locali
echo   -volumes   rimuove anche i volumi
exit /b 0

:usage_error
echo.
echo Per l'elenco delle opzioni: scripts\stop.bat --help
exit /b 1
