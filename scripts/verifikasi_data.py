"""Rekam isi kelima collection Firestore sebagai bukti Minggu 10.

Memakai token OAuth pemilik project (firebase-tools) untuk membaca langsung
dari server, bukan dari cache aplikasi. Hasil:
docs/minggu-10/isi-firestore.json

    python scripts/verifikasi_data.py
"""

from __future__ import annotations

import json
import time
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

PROJECT_ID = "toko-skincare-fec17"
ROOT = (
    "https://firestore.googleapis.com/v1/projects/"
    f"{PROJECT_ID}/databases/(default)/documents"
)
ADMIN_UID = "JRYpdzItPOcyCYHNI2plizDAyHg1"
PELANGGAN_UID = "stjEG021jVXudJIN0uY57wdhoDq1"


def _token() -> str:
    p = Path.home() / ".config" / "configstore" / "firebase-tools.json"
    t = json.loads(p.read_text(encoding="utf-8"))["tokens"]
    if t.get("expires_at", 0) < int(time.time() * 1000):
        raise SystemExit("Token kedaluwarsa; jalankan `firebase login:list` dulu.")
    return t["access_token"]


def _get(url: str, token: str) -> dict:
    req = urllib.request.Request(url, headers={"Authorization": "Bearer " + token})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode("utf-8"))


def _dokumen(path: str, token: str) -> list[str]:
    try:
        return [d["name"].split("/")[-1]
                for d in _get(f"{ROOT}/{path}?pageSize=100", token).get("documents", [])]
    except Exception as e:  # noqa: BLE001
        return [f"ERROR: {e}"]


def _str(fields: dict, key: str) -> str:
    return (fields.get(key) or {}).get("stringValue", "")


def main() -> None:
    token = _token()
    roles = {}
    for uid, label in [(ADMIN_UID, "admin"), (PELANGGAN_UID, "pelanggan")]:
        try:
            doc = _get(f"{ROOT}/users/{uid}", token)
            roles[label] = {"uid": uid, "role": _str(doc["fields"], "role")}
        except Exception as e:  # noqa: BLE001
            roles[label] = {"uid": uid, "role": f"ERROR: {e}"}

    data = {
        "tanggal": datetime.now(timezone.utc).isoformat(),
        "project": PROJECT_ID,
        "lokasi": "asia-southeast2",
        "collections": {
            "users": _dokumen("users", token),
            "products": _dokumen("products", token),
            "skin_profiles": _dokumen("skin_profiles", token),
            "orders": _dokumen("orders", token),
            "carts": _dokumen("carts", token),
            "carts/{pelanggan}/items": _dokumen(
                f"carts/{PELANGGAN_UID}/items", token
            ),
        },
        "jumlah": {},
        "role": roles,
    }
    for k, v in data["collections"].items():
        data["jumlah"][k] = len(v)

    out = Path(__file__).resolve().parents[1] / "docs" / "minggu-10" / "isi-firestore.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    for k, v in data["jumlah"].items():
        print(f"{k:28s}: {v}")
    print("role:", json.dumps(roles, ensure_ascii=False))
    print("->", out)


if __name__ == "__main__":
    main()
