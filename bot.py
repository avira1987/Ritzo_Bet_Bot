#!/usr/bin/env python3
"""
RitzoBet Telegram Bot
- Start message with banner and inline buttons
- Daily forward of latest @ritzobet channel post to users
- Admin panel for editing buttons
"""

import json
import logging
import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from telegram import InlineKeyboardButton, InlineKeyboardMarkup, Update
from telegram.ext import (
    Application,
    CallbackQueryHandler,
    CommandHandler,
    ContextTypes,
    MessageHandler,
    filters,
)

# Paths
BASE_DIR = Path(__file__).resolve().parent
CONFIG_PATH = BASE_DIR / "config.json"
USERS_PATH = BASE_DIR / "data" / "users.json"
LAST_POST_PATH = BASE_DIR / "data" / "last_post.json"
BANNER_PATH = BASE_DIR / "assets" / "banner.png"
APK_PATH = BASE_DIR / "assets" / "RitzoBet.apk"
LOG_PATH = BASE_DIR / "bot.log"

# Logging setup: console + file, English messages
def setup_logging() -> None:
    """Configure logging to console and file with clear English messages."""
    log_format = "%(asctime)s | %(levelname)-8s | %(message)s"
    date_format = "%Y-%m-%d %H:%M:%S"

    # Root logger
    root = logging.getLogger()
    root.setLevel(logging.DEBUG)

    # Console handler
    console = logging.StreamHandler(sys.stdout)
    console.setLevel(logging.INFO)
    console.setFormatter(logging.Formatter(log_format, datefmt=date_format))
    root.addHandler(console)

    # File handler (append, keeps history)
    LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
    file_handler = logging.FileHandler(LOG_PATH, encoding="utf-8", mode="a")
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(logging.Formatter(log_format, datefmt=date_format))
    root.addHandler(file_handler)

    # Reduce telegram library noise
    logging.getLogger("httpx").setLevel(logging.WARNING)
    logging.getLogger("httpcore").setLevel(logging.WARNING)
    logging.getLogger("telegram").setLevel(logging.WARNING)


log = logging.getLogger(__name__)

# Load env
load_dotenv()
BOT_TOKEN = os.getenv("BOT_TOKEN", "8276515797:AAHyjNr6ICrEX5J3YfZS2fXIQsN8Flh5DBo")
ADMIN_IDS_STR = os.getenv("ADMIN_IDS", "")
CHANNEL_USERNAME = "ritzobet"

# ادمین‌هایی که در حالت ارسال همگانی هستند
broadcast_mode_users: set[int] = set()

START_CAPTION = """⚽️ 🏀 Sport Games
24/7 Online Support 💬
Fast Deposits & Withdrawals 💸
Live Betting Options ✅ Exclusive Promotions 🎁 User-Friendly Interface 📱"""


def load_config() -> dict:
    """Load config from JSON."""
    if CONFIG_PATH.exists():
        with open(CONFIG_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}


def save_config(config: dict) -> None:
    """Save config to JSON."""
    with open(CONFIG_PATH, "w", encoding="utf-8") as f:
        json.dump(config, f, ensure_ascii=False, indent=2)


def load_users() -> list[int]:
    """Load user IDs from JSON."""
    if USERS_PATH.exists():
        with open(USERS_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    return []


def save_users(users: list[int]) -> None:
    """Save user IDs to JSON."""
    USERS_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(USERS_PATH, "w", encoding="utf-8") as f:
        json.dump(users, f)


def load_last_post() -> dict:
    """Load last channel post info."""
    if LAST_POST_PATH.exists():
        with open(LAST_POST_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}


def save_last_post(chat_id: int, message_id: int, last_sent_id: int | None = None) -> None:
    """Save last channel post info."""
    LAST_POST_PATH.parent.mkdir(parents=True, exist_ok=True)
    data: dict = {"chat_id": chat_id, "message_id": message_id}
    if last_sent_id is not None:
        data["last_sent_message_id"] = last_sent_id
    elif LAST_POST_PATH.exists():
        try:
            with open(LAST_POST_PATH, "r", encoding="utf-8") as f:
                old = json.load(f)
                data["last_sent_message_id"] = old.get("last_sent_message_id")
        except (json.JSONDecodeError, OSError):
            pass
    with open(LAST_POST_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f)


def get_admin_ids() -> list[int]:
    """Get admin IDs from config or env."""
    if ADMIN_IDS_STR:
        return [int(x.strip()) for x in ADMIN_IDS_STR.split(",") if x.strip()]
    config = load_config()
    return config.get("admin_ids", [109374387, 332935318])


def build_start_keyboard() -> InlineKeyboardMarkup:
    """Build inline keyboard from config."""
    config = load_config()
    cg = config.get("claim_gift", {"text": "🎁 Claim Gift !", "url": "https://t.me/RitzoBet"})
    flags = config.get("flags", {})
    apk = config.get("download_apk", {"text": "📱 Download App", "url": ""})

    # Download button: use URL if set, otherwise callback to send file
    apk_url = apk.get("url", "").strip()
    if apk_url and apk_url.startswith("http"):
        apk_button = InlineKeyboardButton(apk.get("text", "📱 Download App"), url=apk_url)
    else:
        apk_button = InlineKeyboardButton(apk.get("text", "📱 Download App"), callback_data="send_apk")

    keyboard = [
        [InlineKeyboardButton(cg["text"], url=cg["url"])],
        [
            InlineKeyboardButton(
                flags.get("england", {}).get("text", "🇬🇧"),
                url=flags.get("england", {}).get("url", "https://t.me/RitzoBet"),
            ),
            InlineKeyboardButton(
                flags.get("turkey", {}).get("text", "🇹🇷"),
                url=flags.get("turkey", {}).get("url", "https://t.me/RitzoBet"),
            ),
        ],
        [
            InlineKeyboardButton(
                flags.get("uzbekistan", {}).get("text", "🇺🇿"),
                url=flags.get("uzbekistan", {}).get("url", "https://t.me/RitzoBet"),
            ),
            InlineKeyboardButton(
                flags.get("bangladesh", {}).get("text", "🇧🇩"),
                url=flags.get("bangladesh", {}).get("url", "https://t.me/RitzoBet"),
            ),
        ],
        [apk_button],
    ]
    return InlineKeyboardMarkup(keyboard)


class ChannelPostFilter(filters.UpdateFilter):
    """Filter for channel posts from @ritzobet."""

    def filter(self, update: Update) -> bool:
        if update.channel_post:
            chat = update.channel_post.chat
            return bool(chat.username and chat.username.lower() == CHANNEL_USERNAME.lower())
        return False


class BroadcastModeFilter(filters.UpdateFilter):
    """Filter for messages from admins in broadcast mode."""

    def filter(self, update: Update) -> bool:
        if not update.message or not update.effective_user:
            return False
        return update.effective_user.id in broadcast_mode_users


def admin_only(func):
    """Decorator to restrict handlers to admins."""

    async def wrapper(update: Update, context: ContextTypes.DEFAULT_TYPE):
        user_id = update.effective_user.id if update.effective_user else 0
        if user_id not in get_admin_ids():
            await update.message.reply_text("⛔ دسترسی غیرمجاز.")
            return
        return await func(update, context)

    return wrapper


async def start_handler(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Handle /start command."""
    user_id = update.effective_user.id if update.effective_user else 0
    username = update.effective_user.username if update.effective_user else "?"
    users = load_users()
    is_new = user_id not in users
    if is_new:
        users.append(user_id)
        save_users(users)
        log.info("New user started: user_id=%s username=@%s", user_id, username)
    else:
        log.debug("Existing user /start: user_id=%s", user_id)

    photo = BANNER_PATH if BANNER_PATH.exists() else None
    keyboard = build_start_keyboard()

    try:
        if photo:
            await update.message.reply_photo(
                photo=str(photo),
                caption=START_CAPTION,
                reply_markup=keyboard,
            )
        else:
            await update.message.reply_text(
                START_CAPTION,
                reply_markup=keyboard,
            )
        log.debug("Start message sent to user_id=%s (photo=%s)", user_id, bool(photo))
    except Exception as e:
        log.exception("Failed to send start message to user_id=%s: %s", user_id, e)
        raise


async def download_apk_handler(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Send APK file when user clicks download button."""
    query = update.callback_query
    user_id = update.effective_user.id if update.effective_user else 0
    await query.answer()
    if query.data != "send_apk":
        return
    if not APK_PATH.exists():
        log.warning("APK download requested but file not found: %s", APK_PATH)
        await query.message.reply_text("⚠️ فایل اپلیکیشن در حال حاضر موجود نیست.")
        return
    try:
        await query.message.reply_document(
            document=str(APK_PATH),
            filename="RitzoBet.apk",
        )
        log.info("APK sent to user_id=%s", user_id)
    except Exception as e:
        log.exception("Failed to send APK to user_id=%s: %s", user_id, e)
        await query.message.reply_text(f"❌ خطا در ارسال فایل: {e}")


async def channel_post_handler(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Store latest channel post from @ritzobet."""
    post = update.channel_post
    if post and post.chat:
        save_last_post(post.chat.id, post.message_id)
        log.info("Channel post stored: chat_id=%s message_id=%s", post.chat.id, post.message_id)


async def daily_forward_job(context: ContextTypes.DEFAULT_TYPE) -> None:
    """Job to forward latest channel post to all users."""
    last = load_last_post()
    if not last or "chat_id" not in last or "message_id" not in last:
        log.debug("Daily forward skipped: no channel post stored yet")
        return

    users = load_users()
    bot = context.bot
    from_chat = last["chat_id"]
    msg_id = last["message_id"]
    log.info("Daily forward started: forwarding to %s users", len(users))

    sent, failed = 0, 0
    for user_id in users:
        try:
            await bot.copy_message(
                chat_id=user_id,
                from_chat_id=from_chat,
                message_id=msg_id,
            )
            sent += 1
        except Exception as e:
            failed += 1
            log.debug("Forward failed for user_id=%s: %s", user_id, e)
    log.info("Daily forward done: sent=%s failed=%s", sent, failed)


async def broadcast_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """دستور /broadcast - ارسال پیام به همه کاربران (فقط ادمین)."""
    user_id = update.effective_user.id if update.effective_user else 0
    if user_id not in get_admin_ids():
        log.warning("Unauthorized broadcast attempt by user_id=%s", user_id)
        await update.message.reply_text("⛔ دسترسی غیرمجاز.")
        return
    broadcast_mode_users.add(user_id)
    log.info("Admin user_id=%s entered broadcast mode", user_id)
    context.user_data["broadcast_mode"] = True
    context.user_data.pop("admin_edit_key", None)
    context.user_data.pop("admin_edit_label", None)
    await update.message.reply_text(
        "📤 پیام، عکس، یا فایلی که می‌خواهید برای همه کاربران ارسال شود را بفرستید.\n"
        "برای انصراف: /cancel"
    )


async def broadcast_message_handler(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """ارسال پیام ادمین به همه کاربران وقتی در حالت broadcast است."""
    if not context.user_data.get("broadcast_mode"):
        return
    user_id = update.effective_user.id if update.effective_user else 0
    if user_id not in get_admin_ids():
        return

    if update.message.text and update.message.text.strip() == "/cancel":
        context.user_data.pop("broadcast_mode", None)
        broadcast_mode_users.discard(user_id)
        await update.message.reply_text("❌ ارسال همگانی لغو شد.")
        return

    users = load_users()
    bot = context.bot
    sent = 0
    failed = 0

    for uid in users:
        try:
            await bot.copy_message(
                chat_id=uid,
                from_chat_id=update.effective_chat.id,
                message_id=update.message.message_id,
            )
            sent += 1
        except Exception:
            failed += 1

    context.user_data.pop("broadcast_mode", None)
    broadcast_mode_users.discard(user_id)
    log.info("Broadcast completed by admin user_id=%s: sent=%s failed=%s", user_id, sent, failed)
    await update.message.reply_text(f"✅ ارسال شد به {sent} کاربر." + (f" ({failed} خطا)" if failed else ""))


async def admin_handler(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Handle /admin - show edit menu (admin only)."""
    user_id = update.effective_user.id if update.effective_user else 0
    if user_id not in get_admin_ids():
        log.warning("Unauthorized /admin attempt by user_id=%s", user_id)
        await update.message.reply_text("⛔ دسترسی غیرمجاز.")
        return
    log.info("Admin panel opened by user_id=%s", user_id)

    keyboard = [
        [
            InlineKeyboardButton("🎁 Claim Gift", callback_data="edit_claim_gift"),
            InlineKeyboardButton("📱 Download App", callback_data="edit_apk"),
        ],
        [
            InlineKeyboardButton("🇬🇧 انگلستان", callback_data="edit_flag_england"),
            InlineKeyboardButton("🇹🇷 ترکیه", callback_data="edit_flag_turkey"),
        ],
        [
            InlineKeyboardButton("🇺🇿 ازبکستان", callback_data="edit_flag_uzbekistan"),
            InlineKeyboardButton("🇧🇩 بنگلادش", callback_data="edit_flag_bangladesh"),
        ],
        [InlineKeyboardButton("✅ ذخیره و خروج", callback_data="admin_done")],
    ]
    await update.message.reply_text(
        "⚙️ پنل ویرایش دکمه‌ها. یکی را انتخاب کنید:",
        reply_markup=InlineKeyboardMarkup(keyboard),
    )


async def admin_callback_handler(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Handle admin panel callbacks."""
    query = update.callback_query
    await query.answer()

    user_id = update.effective_user.id if update.effective_user else 0
    if user_id not in get_admin_ids():
        await query.edit_message_text("⛔ دسترسی غیرمجاز.")
        return

    data = query.data
    config = load_config()

    if data == "admin_done":
        await query.edit_message_text("✅ تنظیمات ذخیره شد.")
        return

    # For now, we show current values and ask for new URL via reply
    # Full ConversationHandler would allow multi-step editing - simplified here
    edit_map = {
        "edit_claim_gift": ("claim_gift", "Claim Gift"),
        "edit_apk": ("download_apk", "Download App"),
        "edit_flag_england": ("flags.england", "انگلستان"),
        "edit_flag_turkey": ("flags.turkey", "ترکیه"),
        "edit_flag_uzbekistan": ("flags.uzbekistan", "ازبکستان"),
        "edit_flag_bangladesh": ("flags.bangladesh", "بنگلادش"),
    }

    if data in edit_map:
        key, label = edit_map[data]
        if key.startswith("flags."):
            flag_key = key.split(".")[1]
            current = config.get("flags", {}).get(flag_key, {}).get("url", "")
        elif key == "claim_gift":
            current = config.get("claim_gift", {}).get("url", "")
        else:
            current = config.get("download_apk", {}).get("url", "")

        await query.edit_message_text(
            f"📝 لینک فعلی {label}: {current}\n\n"
            "برای تغییر، لینک جدید را ارسال کنید (یا /cancel برای انصراف):"
        )
        context.user_data["admin_edit_key"] = key
        context.user_data["admin_edit_label"] = label


async def admin_url_reply_handler(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Handle admin's URL reply for button editing."""
    if not context.user_data.get("admin_edit_key"):
        return
    user_id = update.effective_user.id if update.effective_user else 0
    if user_id not in get_admin_ids():
        return

    key = context.user_data.get("admin_edit_key")
    if not key:
        return

    text = update.message.text
    if text and text.startswith("/cancel"):
        context.user_data.pop("admin_edit_key", None)
        context.user_data.pop("admin_edit_label", None)
        await update.message.reply_text("❌ انصراف.")
        return

    if not text or not text.startswith("http"):
        await update.message.reply_text("⚠️ لطفاً یک URL معتبر ارسال کنید (با https://)")
        return

    config = load_config()

    if key.startswith("flags."):
        flag_key = key.split(".")[1]
        if "flags" not in config:
            config["flags"] = {}
        if flag_key not in config["flags"]:
            config["flags"][flag_key] = {"text": "", "url": ""}
        config["flags"][flag_key]["url"] = text.strip()
    elif key == "claim_gift":
        if "claim_gift" not in config:
            config["claim_gift"] = {"text": "🎁 Claim Gift !", "url": ""}
        config["claim_gift"]["url"] = text.strip()
    elif key == "download_apk":
        if "download_apk" not in config:
            config["download_apk"] = {"text": "📱 Download App", "url": ""}
        config["download_apk"]["url"] = text.strip()

    save_config(config)
    context.user_data.pop("admin_edit_key", None)
    context.user_data.pop("admin_edit_label", None)
    await update.message.reply_text("✅ ذخیره شد.")


def main() -> None:
    """Run the bot."""
    setup_logging()
    log.info("RitzoBet bot starting...")
    log.info("Config: CONFIG_PATH=%s, BANNER=%s, APK=%s", CONFIG_PATH, BANNER_PATH, APK_PATH)

    app = Application.builder().token(BOT_TOKEN).build()

    # Log all errors from handlers with full traceback
    async def error_handler(update: object, context: ContextTypes.DEFAULT_TYPE) -> None:
        err = context.error
        if err:
            log.error(
                "Unhandled error: %s | update=%s",
                err,
                update,
                exc_info=(type(err), err, err.__traceback__),
            )
        else:
            log.warning("Error handler called with no context.error")

    app.add_error_handler(error_handler)

    app.add_handler(CommandHandler("start", start_handler))
    app.add_handler(CommandHandler("broadcast", broadcast_command))
    app.add_handler(CommandHandler("admin", admin_handler))
    app.add_handler(MessageHandler(ChannelPostFilter(), channel_post_handler))
    app.add_handler(
        CallbackQueryHandler(download_apk_handler, pattern="^send_apk$"),
    )
    app.add_handler(CallbackQueryHandler(admin_callback_handler))
    app.add_handler(
        MessageHandler(BroadcastModeFilter(), broadcast_message_handler),
    )
    app.add_handler(
        MessageHandler(
            filters.TEXT & ~filters.COMMAND & ~BroadcastModeFilter(),
            admin_url_reply_handler,
        ),
    )

    if app.job_queue:
        # هر ۱۲ ساعت چک کن؛ اگر پست جدیدی هست که هنوز ارسال نشده، بفرست
        app.job_queue.run_repeating(daily_forward_job, interval=43200, first=60)

    log.info("Log file: %s", LOG_PATH)
    app.run_polling(
        allowed_updates=["message", "channel_post", "callback_query"],
    )
    log.info("Bot stopped.")


if __name__ == "__main__":
    main()
