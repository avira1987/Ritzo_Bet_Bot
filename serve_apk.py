#!/usr/bin/env python3
"""
Direct APK download server - no 50MB limit.
Run: python serve_apk.py
URL: http://SERVER_IP:8080/RitzoBet.apk
"""

import http.server
import socketserver
from pathlib import Path

PORT = 8080
BASE_DIR = Path(__file__).resolve().parent
ASSETS_DIR = BASE_DIR / "assets"


def find_apk() -> Path | None:
    """Find APK in root or assets."""
    for p in (BASE_DIR / "RitzoBet.apk", BASE_DIR / "RitzoBet .apk", ASSETS_DIR / "RitzoBet.apk"):
        if p.exists():
            return p
    return None


class APKHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ASSETS_DIR), **kwargs)

    def do_GET(self):
        if self.path == "/RitzoBet.apk":
            apk = find_apk()
            if apk:
                self.send_response(200)
                self.send_header("Content-Type", "application/vnd.android.package-archive")
                self.send_header("Content-Disposition", 'attachment; filename="RitzoBet.apk"')
                self.send_header("Content-Length", str(apk.stat().st_size))
                self.end_headers()
                with open(apk, "rb") as f:
                    self.wfile.write(f.read())
                return
        return super().do_GET()

    def log_message(self, format, *args):
        print(f"[{self.log_date_time_string()}] {format % args}")


if __name__ == "__main__":
    apk = find_apk()
    if apk:
        print(f"APK found: {apk} ({apk.stat().st_size // (1024*1024)} MB)")
    else:
        print("WARNING: RitzoBet.apk not found in project root or assets/")
    with socketserver.TCPServer(("", PORT), APKHandler) as httpd:
        print(f"Direct download: http://0.0.0.0:{PORT}/RitzoBet.apk")
        httpd.serve_forever()
