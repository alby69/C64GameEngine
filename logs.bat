@echo off
rem Wrapper comodo dal root del progetto -> scripts\logs.bat
call "%~dp0scripts\logs.bat" %*
exit /b %ERRORLEVEL%
