@echo off
echo === RitzoBet Bot - Deploy to Windows Server ===
echo.
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File deploy_windows.ps1
echo.
pause
