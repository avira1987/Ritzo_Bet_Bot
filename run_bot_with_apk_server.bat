@echo off
cd /d "%~dp0"

echo Stopping old processes...
taskkill /F /IM python.exe 2>nul
timeout /t 2 /nobreak >nul

echo Starting APK download server (port 8080)...
start "APK Server" /B python serve_apk.py

timeout /t 2 /nobreak >nul

echo Starting bot...
python bot.py

pause
