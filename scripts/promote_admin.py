"""Jadikan sebuah akun sebagai admin di Firestore (bypass Security Rules).

Kenapa perlu skrip ini?
-----------------------
`firestore.rules` sengaja memaksa `role == 'pelanggan'` pada saat dokumen
`users/{uid}` dibuat. Artinya klien TIDAK bisa mengangkat dirinya sendiri
menjadi admin. Satu-satunya jalan yang aman adalah Firebase Console atau
Admin SDK / REST API memakai kredensial pemilik project. Skrip ini memakai
token OAuth yang sudah disimpan `firebase-tools` setelah `firebase login`.

Cara pakai (dari root project):
    firebase login
    python scripts/promote_admin.py                       # admin@skincare.id
    python scripts/promote_admin.py rina@mail.com
    python scripts/promote_admin.py admin@skincare.id --pelanggan

Token kedaluwarsa? Jalankan `firebase login:list` atau perintah firebase apa
pun sekali untuk memicu refresh, lalu jalankan ulang skrip ini.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

PROJECT_ID = "toko-skincare-fec17"
FIRESTORE_DB = "(default)"
DEFAULT_EMAIL = "admin@skincare.id"
TOKEN_FILE = Path.home() / ".config" / "configstore" / "firebase-tools.json"


def _token() -> str:
    if not TOKEN_FILE.exists():
        sys.exit("Token Firebase CLI tidak ditemukan. Jalankan: firebase login")
    data = json.loads(TOKEN_FILE.read_text(encoding="utf-8"))
    tokens = data.get("tokens") or {}
    expires_at = tokens.get("expires_at", 0)
    if expires_at and expires_at < int(time.time() * 1000):
        sys.exit(
            "Token kedaluwarsa. Jalankan `firebase login:list` sekali, "
            "lalu ulangi skrip ini."
        )
    access = tokens.get("access_token")
    if not access:
        sys.exit("access_token kosong. Jalankan: firebase login --reauth")
    return access


def _request(url: str, token: str, body: dict, method: str = "POST") -> dict:
    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode("utf-8"),
        method=method,
        headers={
            "Authorization": "Bearer " + token,
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        sys.exit(f"HTTP {e.code}: {e.read().decode('utf-8')[:500]}")


def _cari_uid(email: str, token: str) -> str:
    url = (
        "https://identitytoolkit.googleapis.com/v1/projects/"
        f"{PROJECT_ID}/accounts:lookup"
    )
    hasil = _request(url, token, {"email": [email]})
    users = hasil.get("users") or []
    if not users:
        sys.exit(
            f"Akun {email} belum ada. Daftarkan dulu lewat halaman Daftar "
            "aplikasi, lalu jalankan ulang skrip ini."
        )
    return users[0]["localId"]


def _simpan_role(uid: str, email: str, nama: str, role: str, token: str) -> None:
    # PATCH tanpa updateMask = upsert: dokumen dibuat bila belum ada.
    url = (
        "https://firestore.googleapis.com/v1/projects/"
        f"{PROJECT_ID}/databases/{FIRESTORE_DB}/documents/users/{uid}"
    )
    fields = {
        "uid": {"stringValue": uid},
        "nama": {"stringValue": nama},
        "email": {"stringValue": email},
        "role": {"stringValue": role},
        "createdAt": {"timestampValue": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())},
    }
    _request(url, token, {"fields": fields}, method="PATCH")
    print(f"users/{uid} -> role='{role}' ({email})")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("email", nargs="?", default=DEFAULT_EMAIL)
    parser.add_argument(
        "--pelanggan",
        action="store_true",
        help="Turunkan kembali menjadi pelanggan (demote).",
    )
    args = parser.parse_args()

    token = _token()
    uid = _cari_uid(args.email, token)
    role = "pelanggan" if args.pelanggan else "admin"
    nama = "Admin Toko" if role == "admin" else args.email.split("@")[0]
    _simpan_role(uid, args.email, nama, role, token)
    print("Selesai. Refresh halaman aplikasi agar peran baru terbaca.")


if __name__ == "__main__":
    main()
