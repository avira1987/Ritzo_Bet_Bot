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

# Copy data
if (Test-Path "$Source\data") {
    New-Item -ItemType Directory -Path "$Dest\data" -Force | Out-Null
    Copy-Item "$Source\data\*" "$Dest\data\" -Force -Recurse
}

# Stop old bot
taskkill /F /IM python.exe 2>$null
Start-Sleep -Seconds 2

# Start bot
Set-Location $Dest
Start-Process python -ArgumentList "bot.py" -WindowStyle Hidden -RedirectStandardOutput "bot.log" -RedirectStandardError "bot.log"

Write-Host "Bot restarted. Check: Get-Content $Dest\bot.log -Tail 20" -ForegroundColor Green
