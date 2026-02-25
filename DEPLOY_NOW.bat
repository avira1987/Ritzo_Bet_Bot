@echo off
echo === RitzoBet Bot - آخرین آپدیت روی سرور ===
echo.
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File deploy.ps1
echo.
pause
