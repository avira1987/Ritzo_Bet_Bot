# ارسال/دانلود فایل APK (بیش از ۵۰ مگابایت)

## روش ساده: serve_apk.py (پیشنهادی)

بدون نیاز به telegram-bot-api.exe:

1. فایل `RitzoBet.apk` را در ریشه پروژه یا `assets/` قرار دهید
2. همزمان با بات، سرور را اجرا کنید: `python serve_apk.py`
3. در `config.json` مقدار `download_apk.url` را `http://IP:8080/RitzoBet.apk` قرار دهید
4. کاربر با کلیک روی دکمه، مستقیماً فایل را دانلود می‌کند

یا از `run_bot_with_apk_server.bat` استفاده کنید که هر دو را اجرا می‌کند.

---

## روش پیشرفته: Local Bot API Server

تلگرام برای بات‌ها حداکثر **۵۰ مگابایت** فایل مجاز است. برای **ارسال فایل در چت** (نه لینک)، باید از **Local Bot API Server** استفاده کنید.

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
