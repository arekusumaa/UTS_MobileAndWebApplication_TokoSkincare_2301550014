"""Uji Firestore Security Rules secara langsung lewat REST API.

Kenapa REST dan bukan hanya klik di UI?
--------------------------------------
Dengan meminta ID token Firebase untuk akun pelanggan dan admin, lalu
mengirimnya sebagai `Authorization: Bearer`, kita bisa membuktikan bahwa
**server** (bukan hanya tombol di UI) yang menolak operasi terlarang.
Ini mendeteksi aturan yang kelewat longgar, misalnya `allow write: if true`.

Cara pakai:
    python scripts/uji_rules.py

Hasil ditulis ke docs/minggu-10/hasil-uji-rules.json.
"""

from __future__ import annotations

import json
import os
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

PROJECT_ID = "toko-skincare-fec17"
API_KEY = "AIzaSyAHexumbwDleZqnW_ooK7rxbnGAMyFqNgc"
ROOT = (
    "https://firestore.googleapis.com/v1/projects/"
    f"{PROJECT_ID}/databases/(default)/documents"
)
ADMIN_EMAIL = "admin@skincare.id"
PELANGGAN_EMAIL = "rina@mail.com"
PASSWORD = "123456"
UJI_DOC = "UJI-RULES-001"

HASIL: list[dict] = []


def _http(url: str, method: str = "GET", body: dict | None = None,
          token: str | None = None, auth: bool = True):
    headers = {"Content-Type": "application/json"}
    if auth and token:
        headers["Authorization"] = "Bearer " + token
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            raw = r.read().decode("utf-8")
            try:
                return r.status, json.loads(raw)
            except json.JSONDecodeError:
                return r.status, {"raw": raw[:300]}
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8")
        try:
            return e.code, json.loads(raw)
        except json.JSONDecodeError:
            return e.code, {"raw": raw[:300]}
    except Exception as e:  # noqa: BLE001
        return -1, {"error": str(e)}


def _token_pemilik() -> str:
    """Token OAuth firebase-tools (setara Admin SDK, melewati Rules)."""
    p = Path.home() / ".config" / "configstore" / "firebase-tools.json"
    if not p.exists():
        raise SystemExit("Jalankan `firebase login` terlebih dahulu.")
    t = json.loads(p.read_text(encoding="utf-8")).get("tokens") or {}
    if t.get("expires_at", 0) < int(time.time() * 1000):
        raise SystemExit("Token kedaluwarsa; jalankan `firebase login:list` dulu.")
    return t["access_token"]


def _siapkan_profil(uid: str) -> None:
    """Pastikan users/{uid} ada, meniru login pertama pelanggan.

    Dipakai murni sebagai *fixture* agar uji #13 (admin membaca profil
    pelanggan) tidak gagal hanya karena dokumennya belum pernah dibuat.
    """
    owner = _token_pemilik()
    body = {"fields": {
        "uid": _s(uid), "nama": _s("Rina Pelanggan"),
        "email": _s(PELANGGAN_EMAIL), "role": _s("pelanggan"),
    }}
    status, _ = _http(f"{ROOT}/users/{uid}", "PATCH", body, token=owner)
    if status != 200:
        raise SystemExit(f"Gagal menyiapkan users/{uid}: HTTP {status}")


def _login(email: str) -> tuple[str, str]:
    url = (
        "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword"
        f"?key={API_KEY}"
    )
    status, body = _http(
        url, "POST",
        {"email": email, "password": PASSWORD, "returnSecureToken": True},
        auth=False,
    )
    if status != 200 or "idToken" not in body:
        raise SystemExit(f"Login {email} gagal ({status}): {str(body)[:300]}")
    return body["idToken"], body["localId"]


def _s(v) -> dict:
    return {"stringValue": str(v)}


def _i(v) -> dict:
    return {"integerValue": str(int(v))}


def _arr(v) -> dict:
    return {"arrayValue": {"values": [_s(x) for x in v]}}


def _pesan(body) -> str:
    # Endpoint runQuery mengembalikan *array* (streamed), termasuk saat error.
    if isinstance(body, list):
        for item in body:
            if isinstance(item, dict) and "error" in item:
                e = item["error"] or {}
                return str(e.get("message") or e.get("status") or e)[:140]
        return str(body)[:140]
    if not isinstance(body, dict):
        return str(body)[:140]
    err = body.get("error") or {}
    msg = err.get("message") or err.get("status") or str(body)[:120]
    return str(msg)[:140]


def catat(no: int, kasus: str, harapan: str, status: int, body: dict,
          diharapkan_status: int) -> None:
    sesuai = status == diharapkan_status
    HASIL.append({
        "no": no,
        "kasus": kasus,
        "diharapkan": f"HTTP {diharapkan_status} — {harapan}",
        "aktual": f"HTTP {status} — {_pesan(body) if status >= 400 else 'diizinkan'}",
        "status": "SESUI" if sesuai else "TIDAK SESUAI",
    })
    print(f"#{no:02d} {kasus}: HTTP {status} "
          f"{'SESUI' if sesuai else 'TIDAK SESUAI'}")


def main() -> None:
    admin_token, admin_uid = _login(ADMIN_EMAIL)
    user_token, user_uid = _login(PELANGGAN_EMAIL)
    print(f"admin uid     : {admin_uid}")
    print(f"pelanggan uid : {user_uid}")
    _siapkan_profil(user_uid)
    print("fixture       : users/{pelanggan} siap\n")

    # 1 — tanpa token, baca products ditolak
    s, b = _http(f"{ROOT}/products?pageSize=1", auth=False)
    catat(1, "Anonim membaca products", "akses ditolak", s, b, 403)

    # 2 — pelanggan boleh baca products
    s, b = _http(f"{ROOT}/products?pageSize=3", token=user_token)
    catat(2, "Pelanggan membaca products", "diizinkan", s, b, 200)
    jumlah = len(b.get("documents", []))
    print(f"   -> {jumlah} dokumen terbaca (halaman pertama)")

    # 3 — pelanggan dilarang membuat produk
    produk = {
        "fields": {
            "id": _s(UJI_DOC), "nama": _s("Produk Ilegal"),
            "kategori": _s("Serum"), "harga": _i(1000), "stok": _i(1),
            "kandunganAktif": _arr([]), "tipeKulitCocok": _arr([]),
            "paoBulan": _i(12), "manfaat": _s("-"), "caraPakai": _s("-"),
        }
    }
    s, b = _http(f"{ROOT}/products?documentId={UJI_DOC}", "POST",
                 produk, token=user_token)
    catat(3, "Pelanggan membuat produk baru", "akses ditolak", s, b, 403)

    # 4 — pelanggan dilarang mengubah HARGA produk
    s, b = _http(
        f"{ROOT}/products/P01?updateMask.fieldPaths=harga", "PATCH",
        {"fields": {"harga": _i(1)}}, token=user_token,
    )
    catat(4, "Pelanggan mengubah harga P01", "akses ditolak", s, b, 403)

    # 5 — pelanggan dilarang menaikkan stok
    s, b = _http(
        f"{ROOT}/products/P01?updateMask.fieldPaths=stok", "PATCH",
        {"fields": {"stok": _i(9999)}}, token=user_token,
    )
    catat(5, "Pelanggan menaikkan stok P01", "akses ditolak", s, b, 403)

    # 6 — pelanggan dilarang mengangkat dirinya jadi admin
    s, b = _http(f"{ROOT}/users/{user_uid}", "PATCH", {"fields": {
        "uid": _s(user_uid), "nama": _s("Rina"),
        "email": _s(PELANGGAN_EMAIL), "role": _s("admin"),
    }}, token=user_token)
    catat(6, "Pelanggan mengubah role sendiri jadi admin", "akses ditolak",
          s, b, 403)

    # 7 — pelanggan dilarang membaca keranjang orang lain
    s, b = _http(f"{ROOT}/carts/{admin_uid}/items?pageSize=1",
                 token=user_token)
    catat(7, "Pelanggan membaca carts milik admin", "akses ditolak", s, b, 403)

    # 8 — pelanggan dilarang query seluruh orders (tanpa where uid)
    s, b = _http(
        f"{ROOT}:runQuery", "POST",
        {"structuredQuery": {"from": [{"collectionId": "orders"}], "limit": 1}},
        token=user_token,
    )
    catat(8, "Pelanggan query semua orders tanpa filter uid", "akses ditolak",
          s, b, 403)

    # 9 — pelanggan dilarang membuat pesanan atas nama orang lain
    s, b = _http(f"{ROOT}/orders?documentId=UJI-ORDER-ILEGAL", "POST",
                 {"fields": {
                     "uid": _s(admin_uid), "id": _s("UJI-ORDER-ILEGAL"),
                     "items": {"arrayValue": {"values": []}},
                     "total": _i(1000), "status": _s("menunggu"),
                     "alamat": _s("Jl. Uji"),
                 }}, token=user_token)
    catat(9, "Pelanggan membuat order dengan uid orang lain", "akses ditolak",
          s, b, 403)

    # 10 — admin boleh membuat produk (lalu dibersihkan)
    s, b = _http(f"{ROOT}/products?documentId={UJI_DOC}", "POST",
                 produk, token=admin_token)
    catat(10, "Admin membuat produk", "diizinkan", s, b, 200)

    # 11 — admin boleh menghapus produk (bersih-bersih)
    s, b = _http(f"{ROOT}/products/{UJI_DOC}", "DELETE", token=admin_token)
    catat(11, "Admin menghapus produk uji", "diizinkan", s, b, 200)

    # 12 — admin boleh query seluruh orders
    s, b = _http(
        f"{ROOT}:runQuery", "POST",
        {"structuredQuery": {"from": [{"collectionId": "orders"}], "limit": 1}},
        token=admin_token,
    )
    catat(12, "Admin query semua orders", "diizinkan", s, b, 200)

    # 13 — admin boleh membaca dokumen users milik orang lain
    s, b = _http(f"{ROOT}/users/{user_uid}", token=admin_token)
    catat(13, "Admin membaca users/{uid} pelanggan", "diizinkan", s, b, 200)

    out = Path(__file__).resolve().parents[1] / "docs" / "minggu-10" / "hasil-uji-rules.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    ringkas = {
        "tanggal": datetime.now(timezone.utc).isoformat(),
        "project": PROJECT_ID,
        "admin_uid": admin_uid,
        "pelanggan_uid": user_uid,
        "total": len(HASIL),
        "sesuai": sum(1 for h in HASIL if h["status"] == "SESUI"),
        "hasil": HASIL,
    }
    out.write_text(json.dumps(ringkas, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"\n{ringkas['sesuai']}/{ringkas['total']} SESUI -> {out}")
    if ringkas["sesuai"] != ringkas["total"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
