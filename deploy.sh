#!/bin/bash
# Deploy RitzoBet Telegram Bot to Linux server
# Usage: Run on the server or copy files first via scp

set -e

SERVER_USER="${SERVER_USER:-root}"
SERVER_HOST="${SERVER_HOST:-5.188.82.107}"
REMOTE_DIR="/opt/ritzobet-bot"

echo "=== Deploying RitzoBet Bot to $SERVER_USER@$SERVER_HOST ==="

# Create remote directory
ssh "$SERVER_USER@$SERVER_HOST" "mkdir -p $REMOTE_DIR"

# Copy files (run from project root: C:\Users\Administrator\Desktop\bot)
scp bot.py config.json requirements.txt .env.example "$SERVER_USER@$SERVER_HOST:$REMOTE_DIR/"
scp -r assets data "$SERVER_USER@$SERVER_HOST:$REMOTE_DIR/" 2>/dev/null || true
[ -f .env ] && scp .env "$SERVER_USER@$SERVER_HOST:$REMOTE_DIR/" || true

# Create .env if not exists
ssh "$SERVER_USER@$SERVER_HOST" "cd $REMOTE_DIR && [ ! -f .env ] && cp .env.example .env && echo 'Edit .env with your BOT_TOKEN' || true"

# Install and run
ssh "$SERVER_USER@$SERVER_HOST" << 'ENDSSH'
cd /opt/ritzobet-bot

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "Installing Python3..."
    apt-get update && apt-get install -y python3 python3-pip python3-venv
fi

# Create venv and install deps
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Stop existing process if running
pkill -f "python.*bot.py" 2>/dev/null || true
sleep 2

# Run in background
nohup python bot.py > bot.log 2>&1 &
echo $! > bot.pid
echo "Bot started. PID: $(cat bot.pid)"
echo "Logs: tail -f /opt/ritzobet-bot/bot.log"
ENDSSH

echo "=== Deploy complete ==="
