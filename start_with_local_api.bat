@echo off
cd /d "%~dp0"

echo Stopping old processes...
taskkill /F /IM python.exe 2>nul
taskkill /F /IM telegram-bot-api.exe 2>nul
timeout /t 2 /nobreak >nul

REM Find telegram-bot-api
set "API_EXE="
if exist "telegram-bot-api\telegram-bot-api.exe" set "API_EXE=telegram-bot-api\telegram-bot-api.exe"
if exist "telegram-bot-api.exe" set "API_EXE=telegram-bot-api.exe"

if "%API_EXE%"=="" (
    echo ERROR: telegram-bot-api not found. Place it in telegram-bot-api\telegram-bot-api.exe
    pause
    exit /b 1
)

REM Load API credentials from .env (simple)
for /f "tokens=2 delims==" %%a in ('findstr /b "TELEGRAM_API_ID=" .env 2^>nul') do set "API_ID=%%a"
for /f "tokens=2 delims==" %%a in ('findstr /b "TELEGRAM_API_HASH=" .env 2^>nul') do set "API_HASH=%%a"

if "%API_ID%"=="" (
    echo ERROR: Add TELEGRAM_API_ID=your_id to .env
    pause
    exit /b 1
)
if "%API_HASH%"=="" (
    echo ERROR: Add TELEGRAM_API_HASH=your_hash to .env
    pause
    exit /b 1
)

echo Starting Local Bot API Server...
start /B "" "%API_EXE%" --api-id=%API_ID% --api-hash=%API_HASH% --local --http-port=8081

timeout /t 3 /nobreak >nul

set LOCAL_BOT_API_URL=http://127.0.0.1:8081
echo Starting bot...
python bot.py

pause
