#!/usr/bin/env python3
"""
سرور ساده برای سرو فایل APK - لینک مستقیم دانلود
اجرا: python serve_apk.py
آدرس: http://SERVER_IP:8080/RitzoBet.apk
"""

import http.server
import socketserver
from pathlib import Path

PORT = 8080
ASSETS_DIR = Path(__file__).resolve().parent / "assets"

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ASSETS_DIR), **kwargs)

    def log_message(self, format, *args):
        print(f"[{self.log_date_time_string()}] {format % args}")

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"APK server: http://0.0.0.0:{PORT}/RitzoBet.apk")
    httpd.serve_forever()
