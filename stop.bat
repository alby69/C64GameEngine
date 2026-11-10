@echo off
rem Wrapper comodo dal root del progetto -> scripts\stop.bat
call "%~dp0scripts\stop.bat" %*
exit /b %ERRORLEVEL%
