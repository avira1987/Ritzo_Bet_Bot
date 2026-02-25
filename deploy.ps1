# RitzoBet Telegram Bot Deployment Script
# Run from: C:\Users\Administrator\Desktop\bot
# Server: 5.188.82.107 (root)
# Password: H@d4SWfveqGF (enter when prompted)

$SERVER = "root@5.188.82.107"
$REMOTE_DIR = "/opt/ritzobet-bot"
$LOCAL_DIR = "C:\Users\Administrator\Desktop\bot"

Write-Host "=== RitzoBet Bot Deployment ===" -ForegroundColor Cyan

# Step 1: Create remote directory
Write-Host "
[1/6] Creating remote directory..." -ForegroundColor Yellow
ssh -o StrictHostKeyChecking=no $SERVER "mkdir -p $REMOTE_DIR"

# Step 2: Copy bot.py, config.json, .env, serve_apk.py
Write-Host "
[2/6] Copying bot.py, config.json, .env, serve_apk.py..." -ForegroundColor Yellow
scp -o StrictHostKeyChecking=no "$LOCAL_DIR\bot.py" "$LOCAL_DIR\config.json" "$LOCAL_DIR\.env" "$LOCAL_DIR\serve_apk.py" "${SERVER}:${REMOTE_DIR}/"

# Step 3: Copy assets/ folder (شامل RitzoBet.apk)
Write-Host "
[3/6] Copying assets/ folder (APK included)..." -ForegroundColor Yellow
scp -o StrictHostKeyChecking=no -r "$LOCAL_DIR\assets" "${SERVER}:${REMOTE_DIR}/"

# Step 4: Copy data/ folder
Write-Host "
[4/6] Copying data/ folder..." -ForegroundColor Yellow
scp -o StrictHostKeyChecking=no -r "$LOCAL_DIR\data" "${SERVER}:${REMOTE_DIR}/"

# Step 5: Stop existing bot
Write-Host "
[5/6] Stopping existing bot..." -ForegroundColor Yellow
ssh $SERVER "pkill -f 'python.*bot.py' 2>/dev/null; sleep 2; echo Stopped"

# Step 6: Start bot
Write-Host "
[6/6] Starting bot..." -ForegroundColor Yellow
ssh $SERVER "cd $REMOTE_DIR && nohup ./venv/bin/python bot.py > bot.log 2>&1 &"

# Verify
Write-Host "
=== Verification ===" -ForegroundColor Cyan
ssh $SERVER "ps aux | grep bot"

Write-Host "
Deployment complete!" -ForegroundColor Green
Write-Host 'Note: Ensure APK is in assets/RitzoBet.apk.' -ForegroundColor Gray
