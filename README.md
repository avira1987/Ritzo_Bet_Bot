# RitzoBet Telegram Bot

بات تلگرام RitzoBet با قابلیت‌های:
- پیام استارت با بنر و دکمه‌های اینلاین
- فوروارد روزانه آخرین پست کانال @ritzobet به کاربران
- دکمه دانلود اپ اندروید
- پنل ادمین برای ویرایش دکمه‌ها

## نصب

```bash
pip install -r requirements.txt
```

## تنظیمات

1. فایل `.env` را ایجاد کنید (یا از `.env.example` کپی کنید)
2. `BOT_TOKEN` را از @BotFather تنظیم کنید
3. بات را به کانال @ritzobet به عنوان ادمین اضافه کنید

## بنر و اپلیکیشن

- تصویر بنر را در `assets/banner.png` قرار دهید. در صورت نبود، پیام بدون تصویر ارسال می‌شود.
- فایل APK را در `RitzoBet.apk` (ریشه) یا `assets/RitzoBet.apk` قرار دهید. **محدودیت تلگرام: ۵۰ مگابایت.** اگر APK بزرگ‌تر است، در `config.json` مقدار `download_apk.url` را به لینک مستقیم تنظیم کنید (مثلاً با اجرای `serve_apk.py` روی سرور: `http://IP:8080/RitzoBet.apk`).

## اجرا

```bash
python bot.py
```

## دیپلوی روی سرور

```bash
chmod +x deploy.sh
./deploy.sh
```

یا به صورت دستی: فایل‌ها را به سرور کپی کنید و `python bot.py` را با nohup اجرا کنید.
