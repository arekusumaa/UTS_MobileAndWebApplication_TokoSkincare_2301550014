#!/usr/bin/env python3
"""Generate Indonesian TTS narration for the UTS explainer video.

Uses edge-tts (free, no API key) with voice id-ID-GadisNeural.
Writes one mp3 per scene plus durations.json consumed by Remotion.
"""
import asyncio
import json
import os
import sys

import edge_tts
from mutagen.mp3 import MP3

VOICE = "id-ID-GadisNeural"
RATE = "+8%"          # slightly faster so ~3 min target fits comfortably
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "public", "audio")

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


async def synth(name: str, text: str, out_dir: str) -> str:
    path = os.path.join(out_dir, f"{name}.mp3")
    communicate = edge_tts.Communicate(text, VOICE, rate=RATE)
    await communicate.save(path)
    return path


async def main() -> int:
    out_dir = os.path.normpath(OUT_DIR)
    os.makedirs(out_dir, exist_ok=True)

    durations = {}
    for name, text in SCENES:
        path = await synth(name, text, out_dir)
        audio = MP3(path)
        seconds = round(audio.info.length, 3)
        words = len(text.split())
        durations[name] = {"seconds": seconds, "words": words, "file": f"{name}.mp3"}
        print(f"{name:18s} {seconds:7.3f}s  {words:4d} words  {words/seconds:5.2f} w/s")

    total = sum(v["seconds"] for v in durations.values())
    print(f"{'TOTAL':18s} {total:7.3f}s  ({int(total//60)}:{total%60:05.2f})")

    payload = {"voice": VOICE, "rate": RATE, "totalSeconds": round(total, 3), "scenes": durations}
    with open(os.path.join(out_dir, "durations.json"), "w", encoding="utf-8") as fh:
        json.dump(payload, fh, indent=2, ensure_ascii=False)
    print("wrote durations.json")
    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
