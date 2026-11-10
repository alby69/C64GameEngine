@echo off
rem Wrapper comodo dal root del progetto -> scripts\run-game.bat
call "%~dp0scripts\run-game.bat" %*
exit /b %ERRORLEVEL%
