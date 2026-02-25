# نصب وابستگی‌ها و اجرای بات روی Windows Server 2012
# این اسکریپت را روی سرور اجرا کن (PowerShell با دسترسی Administrator)

$BotDir = "C:\ritzobet-bot"
$PythonVersion = "3.10.11"
$PythonInstaller = "python-$PythonVersion-amd64.exe"
$PythonUrl = "https://www.python.org/ftp/python/$PythonVersion/$PythonInstaller"

Write-Host "=== RitzoBet Bot - Setup for Windows Server 2012 ===" -ForegroundColor Cyan

# اگر اسکریپت از داخل پوشه بات اجرا شده، از آنجا استفاده کن
if (Test-Path "$PSScriptRoot\bot.py") {
    $BotDir = $PSScriptRoot
    Write-Host "Bot files found in: $BotDir" -ForegroundColor Gray
}

# ایجاد پوشه
if (!(Test-Path $BotDir)) {
    New-Item -ItemType Directory -Path $BotDir -Force | Out-Null
    Write-Host "Created $BotDir" -ForegroundColor Yellow
}

# بررسی نصب Python
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    Write-Host "`n[1/4] Installing Python $PythonVersion..." -ForegroundColor Yellow
    $installerPath = "$env:TEMP\$PythonInstaller"
    
    try {
        Invoke-WebRequest -Uri $PythonUrl -OutFile $installerPath -UseBasicParsing
        Start-Process -FilePath $installerPath -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0" -Wait
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
        Write-Host "Download Python manually from https://www.python.org/downloads/" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "`n[1/4] Python already installed: $($pythonCmd.Source)" -ForegroundColor Green
}

# به‌روزرسانی PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# نصب وابستگی‌ها
Write-Host "`n[2/4] Installing dependencies..." -ForegroundColor Yellow
Set-Location $BotDir
python -m pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet
if ($LASTEXITCODE -ne 0) {
    pip install python-telegram-bot[job-queue] python-dotenv
}

# متوقف کردن بات قبلی
Write-Host "`n[3/4] Stopping existing bot..." -ForegroundColor Yellow
Get-Process python* -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
taskkill /F /IM python.exe 2>$null
Start-Sleep -Seconds 2

# اجرای بات
Write-Host "`n[4/4] Starting bot..." -ForegroundColor Yellow
Start-Process python -ArgumentList "bot.py" -WorkingDirectory $BotDir -WindowStyle Hidden -RedirectStandardOutput "$BotDir\bot.log" -RedirectStandardError "$BotDir\bot_err.log"

Start-Sleep -Seconds 2
$proc = Get-Process python* -ErrorAction SilentlyContinue
if ($proc) {
    Write-Host "`nBot started! PID: $($proc.Id)" -ForegroundColor Green
} else {
    Write-Host "`nCheck bot.log for errors" -ForegroundColor Yellow
}
Write-Host "Log: $BotDir\bot.log" -ForegroundColor Gray
