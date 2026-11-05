#!/usr/bin/env python3
"""Build a single .srt for the final UTS video.

Timeline of out/uts-skincare-store-final.mp4:
  part A  0.000        -> 232.033   five Remotion scenes (opening .. rancangan)
  part B  232.033      -> 351.166   live prototype screen recording
  part C  351.166      -> 375.667   closing scene

Splits each scene's narration into sentence-sized cues and distributes the
scene's measured audio duration proportionally to character length. Demo cues
reuse the exact offsets baked into the demo audio mix.
"""
import json
import math
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, ".."))
FPS = 30

PART_B_START = 232.0333
PART_B_DURATION = 119.1333

# Must match scripts/tts.py SCENES (text only) and public/audio/durations.json.
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
        "scene5-rancangan",
        "Rancangan aplikasi terdiri dari tiga bagian. "
        "Pertama, user flow. Pengguna masuk dari halaman login, kemudian ke beranda, "
        "mengisi profil kulit, menjelajahi daftar produk, melihat detail produk, "
        "menambahkan ke keranjang, melakukan checkout, dan melihat status pesanan. "
        "Kedua, sitemap. Total ada lima belas halaman. Sebelas halaman pelanggan dan empat halaman admin. "
        "Ketiga, wireframe. Saya membuat wireframe di Figma pada Minggu empat, "
        "dengan lima frame Must dan style guide warna pink D sembilan lima tujuh tujuh delapan. "
        "Wireframe tersebut kemudian saya implementasikan ke Flutter, dan screenshot hasil implementasinya "
        "dapat dilihat di sini.",
    ),
    (
        "scene6-closing",
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
    "scene5-rancangan": 10,
    "scene6-closing": 20,
}


def ts(seconds: float) -> str:
    ms = int(round(seconds * 1000))
    h, ms = divmod(ms, 3_600_000)
    m, ms = divmod(ms, 60_000)
    s, ms = divmod(ms, 1000)
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"


def split_cues(text: str):
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
        # The closing scene is pushed back by the live demo inserted before it.
        if scene_id == "scene6-closing":
            audio_start += PART_B_DURATION
        audio_dur = meta["seconds"]
        cursor_frames += math.ceil(meta["seconds"] * FPS) + TAIL[scene_id]

        pieces = split_cues(text)
        total_chars = sum(len(p) for p in pieces) or 1
        t = audio_start
        for p in pieces:
            dur = audio_dur * (len(p) / total_chars)
            cues.append((t, min(audio_start + audio_dur, t + dur), p))
            t += dur

    # Demo section: exact offsets from scripts/demo-tts.py.
    seg_path = os.path.join(ROOT, "out", "demo", "audio", "segments.json")
    if os.path.exists(seg_path):
        with open(seg_path, encoding="utf-8") as fh:
            segments = json.load(fh)
        for seg in segments:
            start = PART_B_START + seg["start"]
            cues.append((start, start + seg["duration"], seg["text"].strip()))
    else:
        print("warning: demo segments.json missing, skipping demo cues")

    cues.sort(key=lambda c: c[0])

    lines = []
    for i, (start, end, text) in enumerate(cues, start=1):
        lines.append(str(i))
        lines.append(f"{ts(start)} --> {ts(end)}")
        lines.append(text)
        lines.append("")

    out = os.path.join(ROOT, "out", "uts-skincare-store-final.srt")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))
    print(f"wrote {out} ({len(cues)} cues)")


if __name__ == "__main__":
    main()
