@echo off
cd /d "%~dp0"
echo Stopping old bot...
taskkill /F /IM python.exe 2>nul
timeout /t 2 /nobreak >nul
echo Starting bot from %cd%
python bot.py
pause
