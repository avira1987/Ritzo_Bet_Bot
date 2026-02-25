# Apply updates locally - copy from Desktop\bot to ritzobet-bot and restart
# Run this on the SAME machine where the bot runs (e.g. via KVM Console)

$Source = "C:\Users\Administrator\Desktop\bot"
$Dest   = "C:\ritzobet-bot"

Write-Host "Applying updates from $Source to $Dest..." -ForegroundColor Yellow

# Ensure dest exists
New-Item -ItemType Directory -Path $Dest -Force | Out-Null

# Copy files
Copy-Item "$Source\bot.py" "$Dest\" -Force
Copy-Item "$Source\config.json" "$Dest\" -Force
Copy-Item "$Source\.env" "$Dest\" -Force -ErrorAction SilentlyContinue
Copy-Item "$Source\serve_apk.py" "$Dest\" -Force -ErrorAction SilentlyContinue
Copy-Item "$Source\requirements.txt" "$Dest\" -Force -ErrorAction SilentlyContinue

# Copy assets (includes banner.png)
if (Test-Path "$Source\assets") {
    New-Item -ItemType Directory -Path "$Dest\assets" -Force | Out-Null
    Copy-Item "$Source\assets\*" "$Dest\assets\" -Force -Recurse
    Write-Host "  assets/ copied (banner.png, etc.)" -ForegroundColor Green
}
# Copy APK from root if exists
foreach ($apk in @("$Source\RitzoBet.apk", "$Source\RitzoBet .apk")) {
    if (Test-Path $apk) {
        Copy-Item $apk "$Dest\" -Force
        Write-Host "  APK copied from root" -ForegroundColor Green
        break
    }
}

# Copy telegram-bot-api folder (for direct file send in chat)
if (Test-Path "$Source\telegram-bot-api") {
    Copy-Item "$Source\telegram-bot-api" "$Dest\telegram-bot-api" -Recurse -Force
    Write-Host "  telegram-bot-api/ copied" -ForegroundColor Green
}

# Copy data
if (Test-Path "$Source\data") {
    New-Item -ItemType Directory -Path "$Dest\data" -Force | Out-Null
    Copy-Item "$Source\data\*" "$Dest\data\" -Force -Recurse
}

# Stop old processes
taskkill /F /IM python.exe 2>$null
taskkill /F /IM telegram-bot-api.exe 2>$null
Start-Sleep -Seconds 2

Set-Location $Dest

# Check if Local Bot API should be used (TELEGRAM_API_ID in .env)
$useLocalApi = $false
if (Test-Path ".env") {
    $useLocalApi = (Get-Content ".env" | Select-String "^TELEGRAM_API_ID=.+").Count -gt 0
}

if ($useLocalApi -and (Test-Path "telegram-bot-api\telegram-bot-api.exe")) {
    Write-Host "Starting Local Bot API (direct file send in chat)..." -ForegroundColor Green
    $envContent = Get-Content ".env" -Raw
    if ($envContent -match "TELEGRAM_API_ID=(\S+)") { $apiId = $matches[1].Trim() }
    if ($envContent -match "TELEGRAM_API_HASH=(\S+)") { $apiHash = $matches[1].Trim() }
    if ($apiId -and $apiHash) {
        Start-Process "telegram-bot-api\telegram-bot-api.exe" -ArgumentList "--api-id=$apiId","--api-hash=$apiHash","--local","--http-port=8081" -WindowStyle Hidden
        Start-Sleep -Seconds 3
        # Ensure .env has LOCAL_BOT_API_URL=http://127.0.0.1:8081
    }
}

if (-not $useLocalApi) {
    Write-Host "Starting serve_apk (link download)..." -ForegroundColor Yellow
    Start-Process python -ArgumentList "serve_apk.py" -WindowStyle Hidden -RedirectStandardOutput "serve_apk.log" -RedirectStandardError "serve_apk.log"
    Start-Sleep -Seconds 1
}

# Start bot
Start-Process python -ArgumentList "bot.py" -WindowStyle Hidden -RedirectStandardOutput "bot.log" -RedirectStandardError "bot.log"

Write-Host "Bot restarted. Check: Get-Content $Dest\bot.log -Tail 20" -ForegroundColor Green
