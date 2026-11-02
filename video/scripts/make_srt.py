#!/usr/bin/env python3
"""Build a single .srt for the UTS explainer.

Splits each scene's narration into sentence-sized cues and distributes the
scene's measured audio duration proportionally to character length.
"""
import json
import math
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, ".."))
FPS = 30

# Must match scripts/tts.py SCENES (text only) and durations.json (timing).
SCENES = [
    (
        "scene1-opening",
        "Halo, saya Are Kusuma Pratiwi, NIM dua tiga nol satu lima lima nol nol satu empat, "
        "kelas A satu. Aplikasi yang saya kembangkan bernama SkinCare Store, "
        "sebuah toko skincare yang merekomendasikan produk berdasarkan profil kulit penggunanya.",
    ),
    (
        "scene2-masalah",
        "Ada empat masalah yang ingin saya selesaikan. "
        "Pertama, kebingungan memilih produk. Pengguna tidak tahu produk mana yang cocok untuk tipe kulitnya, "
        "sementara di pasaran ada ratusan produk dengan klaim yang saling bertentangan. "
        "Kedua, tidak ada personalisasi. Toko skincare online umumnya hanya menampilkan katalog datar, "
        "tanpa mempertimbangkan profil kulit pembeli, sehingga pengguna harus riset sendiri. "
        "Ketiga, tidak ada informasi masa pakai setelah produk dibuka, atau PAO. "
        "Akibatnya produk aktif seperti vitamin C dan retinol tetap dipakai jauh setelah efektivitasnya hilang. "
        "Keempat, risiko alergi. Pengguna tidak punya cara sistematis untuk mencatat bahan yang membuat kulitnya iritasi. "
        "Keempat masalah ini penting, karena salah memilih skincare bukan hanya membuang uang, "
        "tetapi juga memicu jerawat dan iritasi kulit.",
    ),
    (
        "scene3-target",
        "Pengguna utama aplikasi ini adalah mahasiswa dan dewasa muda usia delapan belas sampai dua puluh lima tahun "
        "yang baru memulai rutinitas skincare. "
        "Persona utama saya bernama Rina, dua puluh satu tahun, mahasiswa semester lima. "
        "Kulitnya berminyak dan cenderung berjerawat, dengan concern jerawat, pori besar, dan kulit kusam. "
        "Ia alergi fragrance, dan budgetnya lima puluh sampai seratus ribu rupiah per produk. "
        "Ia aktif berbelanja online, tetapi bingung memilah produk yang aman untuk kulitnya. "
        "Persona kedua adalah admin toko, yang mengelola katalog produk dan memproses pesanan masuk.",
    ),
    (
        "scene4-scope",
        "Ruang lingkup yang saya kerjakan dibatasi pada lima belas halaman. "
        "Untuk pelanggan ada sebelas halaman: login, register, beranda, daftar produk, detail produk, "
        "keranjang, checkout, status pesanan, riwayat pesanan, profil kulit, dan akun. "
        "Untuk admin ada empat halaman: dashboard, kelola produk, form produk, dan kelola pesanan. "
        "Fitur yang masuk prioritas Must adalah profil kulit, rekomendasi produk, katalog dengan filter, "
        "keranjang dan checkout, serta pelacakan status pesanan. "
        "Profil kulit dan rekomendasi saya prioritaskan karena tanpa keduanya aplikasi ini hanya katalog biasa. "
        "Yang sengaja tidak saya masukkan: pembayaran nyata, notifikasi push, dan unggah foto produk. "
        "Seluruh data masih berupa data simulasi yang tersimpan di memori.",
    ),
    (
        "scene5-closing",
        "Rencana teknisnya, Flutter dan Dart untuk antarmuka, Provider untuk manajemen state, "
        "dan GoRouter untuk navigasi. "
        "Data akan disimpan di Cloud Firestore dengan lima koleksi: users, products, skin profiles, orders, dan carts. "
        "Sekian presentasi dari saya. Terima kasih.",
    ),
]

TAIL = {
    "scene1-opening": 12,
    "scene2-masalah": 12,
    "scene3-target": 12,
    "scene4-scope": 12,
    "scene5-closing": 20,
}


def ts(seconds: float) -> str:
    ms = int(round(seconds * 1000))
    h, ms = divmod(ms, 3_600_000)
    m, ms = divmod(ms, 60_000)
    s, ms = divmod(ms, 1000)
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"


def split_cues(text: str):
    # Sentence-ish split, keeping the delimiter.
    parts = re.split(r"(?<=[.:])\s+", text.strip())
    return [p.strip() for p in parts if p.strip()]


def main() -> None:
    with open(os.path.join(ROOT, "public", "audio", "durations.json"), encoding="utf-8") as fh:
        durations = json.load(fh)["scenes"]

    cues = []
    cursor_frames = 0
    for scene_id, text in SCENES:
        meta = durations[scene_id]
        audio_start = cursor_frames / FPS
        audio_dur = meta["seconds"]
        cursor_frames += math.ceil(meta["seconds"] * FPS) + TAIL[scene_id]

        pieces = split_cues(text)
        total_chars = sum(len(p) for p in pieces) or 1
        t = audio_start
        for p in pieces:
            share = len(p) / total_chars
            dur = audio_dur * share
            cues.append((t, min(audio_start + audio_dur, t + dur), p))
            t += dur

    lines = []
    for i, (start, end, text) in enumerate(cues, start=1):
        lines.append(str(i))
        lines.append(f"{ts(start)} --> {ts(end)}")
        lines.append(text)
        lines.append("")

    out = os.path.join(ROOT, "out", "uts-masalah-target-scope.srt")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))
    print(f"wrote {out} ({len(cues)} cues)")


if __name__ == "__main__":
    main()
