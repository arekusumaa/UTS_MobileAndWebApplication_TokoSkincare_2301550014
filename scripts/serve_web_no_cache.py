"""Sajikan build/web di http://127.0.0.1:8137 dengan header anti-cache.

Dipakai supaya perubahan UI Flutter langsung terlihat setelah rebuild tanpa
perlu Ctrl+F5 berulang kali.

Jalankan:
    python scripts/serve_web_no_cache.py
"""

import os
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

ROOT = os.path.normpath(
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "build", "web")
)
PORT = 8137


class NoCacheHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header(
            "Cache-Control", "no-store, no-cache, must-revalidate, max-age=0"
        )
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()


def main():
    os.chdir(ROOT)
    server = ThreadingHTTPServer(("127.0.0.1", PORT), NoCacheHandler)
    print(f"Melayani {ROOT} di http://127.0.0.1:{PORT}")
    server.serve_forever()


if __name__ == "__main__":
    main()
