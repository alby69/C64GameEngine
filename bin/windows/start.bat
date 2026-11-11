@echo off
rem C64 GAME ENGINE - avvio dello stack Docker (Windows)
rem Auto-detects and runs the appropriate stack
rem ============================================================================

rem Determine project root (go up one level from scripts dir)
for %%A in ("%~dp0..") do set "PROJECT_ROOT=%%~fA"

setlocal enabledelayedexpansion

rem ----- Argomenti -----
set "MODE=prod"
set "BUILD=1"
set "FOREGROUND=0"

:parse_args
if "%~1"=="" goto args_done
if /i "%~1"=="-dev"        ( set "MODE=dev" & shift & goto parse_args )
if /i "%~1"=="--dev"       ( set "MODE=dev" & shift & goto parse_args )
if /i "%~1"=="-nobuild"    ( set "BUILD=0" & shift & goto parse_args )
if /i "%~1"=="--no-build"  ( set "BUILD=0" & shift & goto parse_args )
if /i "%~1"=="-foreground" ( set "FOREGROUND=1" & shift & goto parse_args )
if /i "%~1"=="-h"          goto usage
if /i "%~1"=="--help"      goto usage
echo [FAIL] Opzione sconosciuta: %1
goto usage_error
goto args_done

:args_done

rem ----- Controlli preliminari -----
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

rem ----- Configurazione -----
set "APP_PORT=3000"
set "DEV_PORT=3001"
call :load_env APP_PORT
call :load_env DEV_PORT

set "COMPOSE_FILE=!PROJECT_ROOT!/docker-compose.yml"

if "%MODE%"=="dev" (
    set "PROFILE_ARGS=--profile dev"
    set "SERVICE=dev"
    set "CONTAINER=c64gameengine-dev"
    set "PORT=!DEV_PORT!"
    echo [INFO] Avvio dello stack di SVILUPPO ^(vite, hot reload^)
) else (
    set "PROFILE_ARGS="
    set "SERVICE=app"
    set "CONTAINER=c64gameengine"
    set "PORT=!APP_PORT!"
    echo [INFO] Avvio dello stack di PRODUZIONE ^(nginx^)
)

if "%BUILD%"=="1" (
    set "UP_ARGS=up -d --build --remove-orphans"
) else (
    set "UP_ARGS=up -d --remove-orphans"
)

echo [INFO] docker compose -f !COMPOSE_FILE! !PROFILE_ARGS! !UP_ARGS! !SERVICE!
docker compose -f "!COMPOSE_FILE!" !PROFILE_ARGS! !UP_ARGS! !SERVICE!
if errorlevel 1 (
    echo [FAIL] docker compose ha fallito.
    exit /b 1
)

if "%FOREGROUND%"=="1" (
    echo [INFO] Log in tempo reale ^(Ctrl+C per interrompere^)
    docker compose -f "!COMPOSE_FILE!" !PROFILE_ARGS! logs -f !SERVICE!
    exit /b 0
)

rem ----- Attesa del container -----
echo [INFO] Attesa del container '!CONTAINER!'...
set /a "WAITED=0"
set "STATUS=unknown"

:wait_loop
set "STATUS="
for /f "usebackq delims=" %%s in (`docker inspect -f "{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}" "!CONTAINER!" 2^>nul`) do set "STATUS=%%s"
if "!STATUS!"=="healthy" goto ready
if "!STATUS!"=="running" goto ready
if "!STATUS!"=="exited" goto container_stopped
if "!STATUS!"=="dead" goto container_stopped
if !WAITED! GEQ 120 goto timeout
timeout /t 2 /nobreak >nul
set /a "WAITED+=2"
goto wait_loop

:container_stopped
echo [WARN] Il container '!CONTAINER!' si e' fermo con stato '!STATUS!'.
goto done

:timeout
echo [WARN] Timeout ^(120 s^) in attesa del container '!CONTAINER!' ^(stato: !STATUS!^).

:ready
echo [ OK ] Container '!CONTAINER!' pronto.
:done
echo.
echo [ OK ] C64GameEngine e' online: http://localhost:!PORT!
echo [INFO] Log:     scripts/logs.bat
echo [INFO] Arresto: scripts/stop.bat
exit /b 0

rem ----- :load_env -----
:load_env
if not exist "!ENV_FILE!" goto :eof
set "VALUE="
for /f "usebackq tokens=1,* delims==" %%a in (`findstr /b /c:"%~1=" "!ENV_FILE!" 2^>nul`) do set "VALUE=%%b"
if not defined VALUE goto :eof
set "VALUE=%VALUE:"=%"
set "%~1=%VALUE%"
goto :eof

rem ----- Usage -----
:usage
echo Usage: start.bat [-dev] [-nobuild] [-foreground]
echo.
echo   -dev          avvia lo stack di sviluppo ^(vite + hot reload^)
echo   -nobuild      non ricostruisce le immagini
echo   -foreground   segue i log del container
exit /b 0

:usage_error
echo.
echo Per l'elenco delle opzioni: start.bat --help
exit /b 1