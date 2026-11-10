@echo off
rem Wrapper comodo dal root del progetto -> scripts\start.bat
call "%~dp0scripts\start.bat" %*
exit /b %ERRORLEVEL%
