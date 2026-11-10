@echo off
rem Wrapper comodo dal root del progetto -> scripts\build-game.bat
call "%~dp0scripts\build-game.bat" %*
exit /b %ERRORLEVEL%
