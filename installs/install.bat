@echo off
setlocal
echo Scholarh - Instalare pluginuri pentru Rhino 8
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
set "INSTALL_EXIT=%ERRORLEVEL%"
if not "%INSTALL_EXIT%"=="0" echo Instalarea a esuat. Consultati eroarea de mai sus.
if /I not "%~1"=="-CheckOnly" pause
exit /b %INSTALL_EXIT%
