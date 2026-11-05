#!/usr/bin/env python3
"""Generate Indonesian narration for the live demo recording and mix it in.

Each segment is synthesised separately and placed at an exact offset on the
timeline, so the voice lands on the right screen even though the screen
recording has variable frame timing.
"""
import asyncio
import json
import os
import re
import subprocess
import sys

import edge_tts
from mutagen.mp3 import MP3

VOICE = "id-ID-GadisNeural"
RATE = "+8%"
HERE = os.path.dirname(os.path.abspath(__file__))
VIDEO_DIR = os.path.normpath(os.path.join(HERE, ".."))
AUDIO_DIR = os.path.join(VIDEO_DIR, "out", "demo", "audio")
SILENT = os.path.join(VIDEO_DIR, "out", "demo", "demo-silent.mp4")
OUTPUT = os.path.join(VIDEO_DIR, "out", "demo", "demo-narrated.mp4")
BIN = os.path.join(VIDEO_DIR, "node_modules", "@remotion", "compositor-win32-x64-msvc")
FFMPEG = os.path.join(BIN, "ffmpeg.exe")
FFPROBE = os.path.join(BIN, "ffprobe.exe")

# (start_seconds_on_video, text)
SEGMENTS = [
    (
        2.0,
        "Sekarang saya jalankan prototipe aplikasinya langsung di browser. "
        "Aplikasi ini dibangun dengan Flutter, dan seluruh data masih berupa data simulasi.",
    ),
    (
        14.8,
        "Ini halaman login. Saya masuk memakai akun pelanggan demo.",
    ),
    (
        21.8,
        "Berhasil masuk, saya diarahkan ke beranda.",
    ),
    (
        26.6,
        "Di beranda ada kolom pencarian, ajakan melengkapi profil kulit, "
        "filter kategori, dan rekomendasi produk.",
    ),
    (
        38.6,
        "Menu Produk menampilkan sepuluh produk. "
        "Perhatikan badge stok menipis dan stok habis.",
    ),
    (
        46.2,
        "Saya buka detail produk. Ada kandungan aktif, manfaat, "
        "dan informasi masa pakai atau PAO.",
    ),
    (
        54.2,
        "Produk ditambahkan ke keranjang.",
    ),
    (
        59.8,
        "Di keranjang terlihat item, jumlah, subtotal, ongkos kirim, dan total.",
    ),
    (
        68.0,
        "Saya lanjut ke checkout. Tiga kolom: nama penerima, nomor telepon, "
        "dan alamat lengkap.",
    ),
    (
        76.0,
        "Sekarang saya tekan Buat Pesanan tanpa mengisi apa pun. "
        "Semua kolom wajib langsung menampilkan pesan kesalahan berwarna merah.",
    ),
    (
        86.9,
        "Saya isi nomor telepon dengan huruf, tetapi kolom ini memfilter non-angka "
        "sehingga huruf tidak masuk. Alamat yang terlalu pendek juga ditolak.",
    ),
    (
        100.3,
        "Setelah semua terisi dengan benar, pesan kesalahan hilang.",
    ),
    (
        106.4,
        "Saya tekan Buat Pesanan. Pesanan berhasil dibuat, lalu aplikasi berpindah "
        "ke halaman status pesanan dengan nomor pesanan dan timeline pengiriman.",
    ),
]


def probe_duration(path: str) -> float:
    out = subprocess.run(
        [FFPROBE, "-v", "error", "-show_entries", "format=duration",
         "-of", "default=noprint_wrappers=1:nokey=1", path],
        capture_output=True, text=True, check=True,
    ).stdout.strip()
    return float(out)


async def synth(idx: int, text: str) -> tuple[str, float]:
    path = os.path.join(AUDIO_DIR, f"seg{idx:02d}.mp3")
    communicate = edge_tts.Communicate(text, VOICE, rate=RATE)
    await communicate.save(path)
    return path, MP3(path).info.length


async def main() -> int:
    os.makedirs(AUDIO_DIR, exist_ok=True)

    paths, durations = [], []
    for i, (_, text) in enumerate(SEGMENTS, start=1):
        p, d = await synth(i, text)
        paths.append(p)
        durations.append(d)
        print(f"seg{i:02d}  start {SEGMENTS[i-1][0]:6.1f}s  dur {d:6.2f}s  {len(text.split()):3d}w")

    total_speech = sum(durations)
    print(f"\ntotal speech {total_speech:.2f}s")

    problems = []
    for i in range(len(SEGMENTS) - 1):
        end = SEGMENTS[i][0] + durations[i]
        if end > SEGMENTS[i + 1][0]:
            problems.append(
                f"seg{i+1:02d} ends {end:.2f}s, overlaps seg{i+2:02d} @ {SEGMENTS[i+1][0]:.2f}s"
            )
    if problems:
        print("OVERLAP WARNINGS:")
        for p in problems:
            print("  " + p)
    else:
        print("no overlaps")

    video_dur = probe_duration(SILENT)
    print(f"video duration {video_dur:.2f}s")

    inputs = []
    for p in paths:
        inputs += ["-i", p]

    # Input 0 is the silent video (no audio stream) -> audio inputs start at 1.
    filters = []
    for i, (start, _) in enumerate(SEGMENTS):
        ms = int(round(start * 1000))
        filters.append(f"[{i+1}:a]adelay={ms}|{ms}[a{i}]")
    mix_in = "".join(f"[a{i}]" for i in range(len(paths)))
    filters.append(f"{mix_in}amix=inputs={len(paths)}:normalize=0:dropout_transition=0[mix]")

    cmd = [
        FFMPEG, "-v", "error", "-y",
        "-i", SILENT,
        *inputs,
        "-filter_complex", ";".join(filters),
        "-map", "0:v", "-map", "[mix]",
        "-c:v", "copy",
        "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-ac", "2",
        "-t", f"{video_dur:.3f}",
        OUTPUT,
    ]
    print("\nrunning ffmpeg mix...")
    subprocess.run(cmd, check=True)

    with open(os.path.join(AUDIO_DIR, "segments.json"), "w", encoding="utf-8") as fh:
        json.dump(
            [{"start": s, "duration": round(d, 3), "text": t}
             for (s, t), d in zip(SEGMENTS, durations)],
            fh, indent=2, ensure_ascii=False,
        )
    print(f"wrote {OUTPUT}")
    print(f"final duration {probe_duration(OUTPUT):.2f}s")
    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
