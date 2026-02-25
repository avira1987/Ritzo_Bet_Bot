# Start Local Bot API Server + RitzoBet Bot
# Enables direct APK send in chat (files up to 2GB)
# Requires: TELEGRAM_API_ID, TELEGRAM_API_HASH in .env

$BotDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $BotDir

# Load .env for API credentials
$apiId = $null
$apiHash = $null
if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        if ($_ -match "^TELEGRAM_API_ID=(.+)$") { $apiId = $matches[1].Trim() }
        if ($_ -match "^TELEGRAM_API_HASH=(.+)$") { $apiHash = $matches[1].Trim() }
    }
}

# Find telegram-bot-api executable
$apiExe = $null
foreach ($path in @(
    "$BotDir\telegram-bot-api\telegram-bot-api.exe",
    "$BotDir\telegram-bot-api.exe",
    "$BotDir\telegram-bot-api\telegram-bot-api"
)) {
    if (Test-Path $path) {
        $apiExe = $path
        break
    }
}

if (-not $apiExe) {
    Write-Host "ERROR: telegram-bot-api not found. Place it in:" -ForegroundColor Red
    Write-Host "  $BotDir\telegram-bot-api\telegram-bot-api.exe" -ForegroundColor Yellow
    exit 1
}

if (-not $apiId -or -not $apiHash) {
    Write-Host "ERROR: Add to .env:" -ForegroundColor Red
    Write-Host "  TELEGRAM_API_ID=your_api_id" -ForegroundColor Yellow
    Write-Host "  TELEGRAM_API_HASH=your_api_hash" -ForegroundColor Yellow
    exit 1
}

Write-Host "Stopping old processes..." -ForegroundColor Yellow
taskkill /F /IM python.exe 2>$null
taskkill /F /IM telegram-bot-api.exe 2>$null
Start-Sleep 2

Write-Host "Starting Local Bot API Server (port 8081)..." -ForegroundColor Green
$apiProcess = Start-Process -FilePath $apiExe -ArgumentList "--api-id=$apiId","--api-hash=$apiHash","--local","--http-port=8081" -PassThru -WindowStyle Hidden
Start-Sleep 3

# Add LOCAL_BOT_API_URL to env for this session
$env:LOCAL_BOT_API_URL = "http://127.0.0.1:8081"

Write-Host "Starting bot..." -ForegroundColor Green
python bot.py
