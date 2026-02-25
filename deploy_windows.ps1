# RitzoBet Bot - Deploy to Windows Server
# Server: 5.188.82.107 (administrator)
# Password: H@d4SWfveqGF

$SERVER = "administrator@5.188.82.107"
$REMOTE_DIR = "C:/ritzobet-bot"
$REMOTE_DIR_BACKSLASH = "C:\ritzobet-bot"
$LOCAL_DIR = "C:\Users\Administrator\Desktop\bot"

Write-Host "=== RitzoBet Bot - Windows Server Deployment ===" -ForegroundColor Cyan

# Step 1: Create remote directory
Write-Host "`n[1/6] Creating remote directory..." -ForegroundColor Yellow
ssh -o StrictHostKeyChecking=no $SERVER "if (!(Test-Path '$REMOTE_DIR_BACKSLASH')) { New-Item -ItemType Directory -Path '$REMOTE_DIR_BACKSLASH' -Force }"

# Step 2: Copy main files
Write-Host "`n[2/6] Copying bot.py, config.json, .env, serve_apk.py, requirements.txt, setup_server.ps1..." -ForegroundColor Yellow
scp -o StrictHostKeyChecking=no "$LOCAL_DIR\bot.py" "$LOCAL_DIR\config.json" "$LOCAL_DIR\.env" "$LOCAL_DIR\serve_apk.py" "$LOCAL_DIR\requirements.txt" "$LOCAL_DIR\setup_server.ps1" "$LOCAL_DIR\install_and_run.bat" "${SERVER}:${REMOTE_DIR}\"

# Step 3: Copy assets folder
Write-Host "`n[3/6] Copying assets/ folder (APK included)..." -ForegroundColor Yellow
scp -o StrictHostKeyChecking=no -r "$LOCAL_DIR\assets" "${SERVER}:${REMOTE_DIR}\"

# Step 4: Copy data folder
Write-Host "`n[4/6] Copying data/ folder..." -ForegroundColor Yellow
scp -o StrictHostKeyChecking=no -r "$LOCAL_DIR\data" "${SERVER}:${REMOTE_DIR}\"

# Step 5: Run setup (نصب Python و وابستگی‌ها اگر نصب نیست)
Write-Host "`n[5/6] Running setup (install Python + deps if needed)..." -ForegroundColor Yellow
ssh $SERVER "powershell -ExecutionPolicy Bypass -File '$REMOTE_DIR_BACKSLASH\setup_server.ps1'"

# Verify
Write-Host "`n[6/6] Verification ===" -ForegroundColor Cyan
ssh $SERVER "Get-Process python* -ErrorAction SilentlyContinue | Format-Table Id, ProcessName -AutoSize"

Write-Host "`nDeployment complete!" -ForegroundColor Green
Write-Host "Server: Windows Server 2012 | Path: $REMOTE_DIR" -ForegroundColor Gray
