# یک کامند برای دیپلوی بات روی سرور ویندوز
# کپی و در PowerShell اجرا کن. رمز: H@d4SWfveqGF

Set-Location "C:\Users\Administrator\Desktop\bot"
$s = "administrator@5.188.82.107"
$r = "C:/ritzobet-bot"
$l = "C:\Users\Administrator\Desktop\bot"

Write-Host "Deploy to $s ..." -ForegroundColor Cyan
ssh -o StrictHostKeyChecking=no $s "New-Item -ItemType Directory -Path 'C:\ritzobet-bot' -Force | Out-Null"
scp -o StrictHostKeyChecking=no "$l\bot.py" "$l\config.json" "$l\.env" "$l\serve_apk.py" "$l\requirements.txt" "${s}:${r}\"
scp -o StrictHostKeyChecking=no -r "$l\assets" "$l\data" "${s}:${r}\"
ssh $s "taskkill /F /IM python.exe 2>`$null; Start-Sleep 2; cd C:\ritzobet-bot; Start-Process python -ArgumentList 'bot.py' -WindowStyle Hidden -RedirectStandardOutput 'bot.log' -RedirectStandardError 'bot.log'"
Write-Host "Done!" -ForegroundColor Green
