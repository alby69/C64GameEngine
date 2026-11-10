@echo off
setlocal enabledelayedexpansion
rem ============================================================================
rem  C64 GAME ENGINE - log dello stack Docker (Windows)
rem
rem  Uso:  scripts\logs.bat [-dev]
rem ============================================================================

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%.."

set "SERVICE=app"

:parse_args
if "%~1"=="" goto args_done
if /i "%~1"=="-dev"    ( set "SERVICE=dev" & shift & goto parse_args )
if /i "%~1"=="--dev"   ( set "SERVICE=dev" & shift & goto parse_args )
if /i "%~1"=="-h"      goto usage
if /i "%~1"=="--help"  goto usage
echo [FAIL] Opzione sconosciuta: %1
goto usage_error

:args_done

where docker >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Docker non e' installato: https://docs.docker.com/get-docker/
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

!COMPOSE! -f "!COMPOSE_FILE!" --profile dev logs -f !SERVICE!
exit /b %ERRORLEVEL%

rem ---------------------------------------------------------------------------
rem Usage
rem ---------------------------------------------------------------------------
:usage
echo Usage: scripts\logs.bat [-dev]
echo.
echo   -dev   mostra i log dello stack di sviluppo
exit /b 0

:usage_error
echo.
echo Per l'elenco delle opzioni: scripts\logs.bat --help
exit /b 1
