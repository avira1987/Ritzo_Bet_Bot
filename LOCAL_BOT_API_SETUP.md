# ارسال مستقیم فایل APK در چت (بیش از ۵۰ مگابایت)

## روش: Local Bot API Server

برای ارسال **مستقیم فایل در چت** (کاربر با یک کلیک فایل را در تلگرام دریافت می‌کند):

### ۱. پوشه telegram-bot-api
فایل اجرایی را در `telegram-bot-api/telegram-bot-api.exe` قرار دهید.

### ۲. تنظیم .env
```
TELEGRAM_API_ID=شماره_از_my.telegram.org
TELEGRAM_API_HASH=رشته_از_my.telegram.org
LOCAL_BOT_API_URL=http://127.0.0.1:8081
```

### ۳. اجرا
```
start_with_local_api.bat
```
یا:
```powershell
.\start_local_bot_api.ps1
```

### ۴. فایل APK
فایل `RitzoBet.apk` را در ریشه پروژه یا `assets/` قرار دهید.

## مراحل نصب (ویندوز)

### ۱. دریافت API credentials
1. به https://my.telegram.org بروید
2. با شماره تلگرام وارد شوید
3. به **API development tools** بروید
4. یک اپلیکیشن بسازید و `api_id` و `api_hash` را یادداشت کنید

### ۲. دانلود Telegram Bot API Server
- از https://github.com/tdlib/telegram-bot-api/releases یا پروژه‌های pre-built مثل [perdub/localtelegrambotapi_bin](https://github.com/perdub/localtelegrambotapi_bin)
- یا از https://tdlib.github.io/telegram-bot-api/build.html دستورات build را بگیرید

### ۳. اجرای سرور
```powershell
# با api_id و api_hash دریافتی از my.telegram.org
.\telegram-bot-api.exe --api-id=YOUR_API_ID --api-hash=YOUR_API_HASH --local --http-port=8081
```

### ۴. تنظیم بات
در فایل `.env` اضافه کنید:
```
LOCAL_BOT_API_URL=http://127.0.0.1:8081
```

### ۵. اجرای بات
بات را مثل قبل اجرا کنید. حالا فایل APK مستقیماً ارسال می‌شود (حتی اگر بیش از ۵۰ مگ باشد).

## نکات
- سرور Bot API و بات باید هر دو روی همان ماشین اجرا شوند (یا سرور از بات قابل دسترسی باشد)
- پورت پیش‌فرض سرور: 8081
- اگر سرور روی سرور دیگری است: `LOCAL_BOT_API_URL=http://IP:8081`
