@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: RitzoBet Bot - نصب وابستگی‌ها و اجرا
:: اجرا: دوبار کلیک یا از CMD با Run as Administrator

cd /d "%~dp0"

echo ========================================
echo   RitzoBet Bot - Install and Run
echo ========================================
echo.

:: بررسی Python
python --version >nul 2>&1
if errorlevel 1 (
    echo [1/4] Python not found. Installing Python 3.10...
    set PYTHON_URL=https://www.python.org/ftp/python/3.10.11/python-3.10.11-amd64.exe
    set PYTHON_INSTALLER=%TEMP%\python-3.10.11-amd64.exe
    
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile '%PYTHON_INSTALLER%' -UseBasicParsing"
    if not exist "%PYTHON_INSTALLER%" (
        echo ERROR: Python download failed.
        echo Download manually from https://www.python.org/downloads/
        pause
        exit /b 1
    )
    
    "%PYTHON_INSTALLER%" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
    del "%PYTHON_INSTALLER%" 2>nul
    set "PYTHON_EXE=C:\Program Files\Python310\python.exe"
) else (
    echo [1/4] Python already installed.
    set "PYTHON_EXE=python"
)

echo.
echo [2/4] Upgrading pip...
"%PYTHON_EXE%" -m pip install --upgrade pip --quiet 2>nul

echo.
echo [3/4] Installing dependencies...
"%PYTHON_EXE%" -m pip install python-telegram-bot[job-queue] python-dotenv --quiet 2>nul
if errorlevel 1 (
    "%PYTHON_EXE%" -m pip install -r requirements.txt
)

echo.
echo [4/4] Stopping old bot and starting...
taskkill /F /IM python.exe 2>nul
timeout /t 2 /nobreak >nul

:: اجرای بات در پس‌زمینه
start /B "%PYTHON_EXE%" bot.py > bot.log 2>&1

timeout /t 2 /nobreak >nul
tasklist | findstr /I python.exe >nul 2>&1
if errorlevel 1 (
    echo.
    echo WARNING: Bot may have failed. Check bot.log
) else (
    echo.
    echo Bot started successfully!
)

echo.
echo Log file: %cd%\bot.log
echo.
pause
