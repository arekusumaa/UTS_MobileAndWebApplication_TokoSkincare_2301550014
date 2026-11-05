# Panduan Rekaman Demo Prototype Berjalan

Dokumen ini menjelaskan cara merekam bagian **demo prototype berjalan** pada video UTS
SkinCare Store, yaitu bagian yang membuktikan minimal 3 halaman terhubung dan form
tervalidasi.

Bagian ini **tidak** bisa dihasilkan oleh Remotion, karena Remotion hanya me-render
komposisi React, bukan merekam interaksi aplikasi. Karena itu demo direkam terpisah
dari aplikasi Flutter web yang benar-benar berjalan, lalu disambung ke video utama.

---

## 1. Hasil akhir yang sudah dibuat

| Item | Path |
|---|---|
| Video final (6 menit 15 detik) | `video/out/uts-skincare-store-final.mp4` |
| Subtitle final | `video/out/uts-skincare-store-final.srt` |
| Rekaman demo saja | `video/out/demo/demo-narrated.mp4` |
| Script perekam otomatis | `video/scripts/demo-record.js` |
| Narasi demo | `video/scripts/demo-tts.py` |

Struktur video final:

```
0:00 - 3:52   Lima slide Remotion
              pembuka -> masalah -> target pengguna -> scope -> rancangan
3:52 - 5:51   Rekaman demo prototype berjalan (bagian ini)
5:51 - 6:15   Penutup: rencana teknis + terima kasih
```

---

## 2. Alur yang direkam (dan alasannya)

| Waktu | Layar | Yang dibuktikan |
|---|---|---|
| 0:14 | Login | Form login, isi kredensial, tombol Masuk |
| 0:23 | Beranda | Navigasi berhasil, rekomendasi produk |
| 0:36 | Daftar Produk | Perpindahan lewat NavigationBar |
| 0:43 | Detail Produk | Push route, info PAO |
| 0:51 | SnackBar | Aksi "Lihat" pada notifikasi |
| 0:57 | Keranjang | State keranjang terbawa antar halaman |
| 1:05 | Checkout | Form dengan 3 kolom |
| 1:12 | Validasi gagal | Pesan error merah saat form kosong |
| 1:26 | Validasi input salah | Nomor telepon menolak huruf, alamat terlalu pendek |
| 1:46 | Submit valid | SnackBar sukses + pindah halaman |
| 1:49 | Status Pesanan | Nomor pesanan, timeline, detail |

Ini memenuhi syarat brief: **minimal 3 halaman terhubung** (Beranda, Produk, Detail,
Keranjang, Checkout, Status = 6 halaman) dan **form tervalidasi** (3 kasus uji).

---

## 3. Cara merekam ulang secara otomatis (disarankan)

Perekaman dilakukan dengan Playwright yang mengendalikan Chrome secara nyata:
klik mouse sungguhan, ketikan keyboard sungguhan, lalu direkam menjadi video.

### 3.1 Prasyarat

```bash
cd D:/dev/tokoskincare
flutter build web --release        # pastikan build/web terbaru
cd build/web && python -m http.server 8137 --bind 127.0.0.1
```

Biarkan server berjalan di terminal terpisah.

### 3.2 Rekam

```bash
cd D:/dev/tokoskincare/video
node scripts/demo-record.js --video
```

Script akan:

1. Membuka aplikasi di `http://127.0.0.1:8137/`
2. Mengaktifkan accessibility tree Flutter (`flt-semantics-placeholder`)
3. Menjalankan alur login sampai status pesanan
4. Menyimpan `.webm` ke `out/demo/raw/`
5. Mencetak `VIDEO_PATH=` dan tabel `TIMELINE` berisi penanda waktu tiap layar

### 3.3 Ubah ke MP4 dan tambahkan narasi

```bash
# webm -> mp4 (buang audio, seragamkan 30 fps)
ffmpeg -i out/demo/raw/page@*.webm -vf "scale=1600:900" -r 30 \
  -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -an \
  -y out/demo/demo-silent.mp4

# narasi TTS + mix ke video
python scripts/demo-tts.py
```

`demo-tts.py` menghasilkan satu MP3 per segmen, menaruhnya di offset waktu yang tepat,
lalu menulis `out/demo/demo-narrated.mp4`.

### 3.4 Catatan teknis penting

- **Jangan** memakai `npx playwright install chromium`. Browser diambil dari
  `node_modules/.remotion/chrome-headless-shell/...` (sudah ada karena Remotion),
  diatur lewat `executablePath` di `scripts/lib/flutter.js`.
- Playwright butuh `ffmpeg` sendiri untuk `recordVideo`. Sekali saja:
  `npx playwright@1.64.1 install ffmpeg`.
- `flt-semantics-placeholder` berada di luar viewport, jadi harus
  `dispatchEvent("click")`, bukan `click()`.
- Untuk mengisi field, klik koordinat `<input>` lalu `keyboard.type()`.
  `fill()` dan `evaluate` tidak memperbarui state Flutter.

---

## 4. Cara merekam manual (OBS Studio) — alternatif

Kalau ingin merekam dengan suara sendiri:

1. Jalankan `flutter run -d chrome --release`, atau sajikan `build/web` seperti di atas.
2. OBS: **Display Capture** atau **Window Capture** pada jendela Chrome.
3. Resolusi kanvas 1920x1080, 30 fps.
4. Ikuti urutan di tabel bagian 2, beri jeda 2-3 detik setiap layar.
5. Saat mendemokan validasi, tunjukkan dengan jelas:
   - klik **Buat Pesanan** tanpa isi apa pun → semua error muncul
   - ketik huruf pada **Nomor Telepon** → huruf tidak masuk
   - isi **Alamat** kurang dari 10 karakter → error muncul
   - isi benar semua → SnackBar "Pesanan berhasil dibuat!"
6. Simpan sebagai MP4 H.264.

---

## 5. Menyambung ke video utama

Video final dibangun dari tiga bagian dengan parameter encoding identik
(1920x1080, 30 fps, H.264 CRF 20, AAC 192k 48 kHz stereo):

```bash
cd D:/dev/tokoskincare/video
FF=node_modules/@remotion/compositor-win32-x64-msvc/ffmpeg.exe

# A: lima slide pertama (0 -> 232,033 detik)
"$FF" -i out/full-explainer.mp4 -t 232.0333 -r 30 -c:v libx264 -crf 20 \
  -pix_fmt yuv420p -c:a aac -b:a 192k -ar 48000 -ac 2 -y out/final/part-a.mp4

# B: demo, diskalakan ke 1920x1080
"$FF" -i out/demo/demo-narrated.mp4 -vf "scale=1920:1080" -r 30 \
  -c:v libx264 -crf 20 -pix_fmt yuv420p -c:a aac -b:a 192k -ar 48000 -ac 2 \
  -y out/final/part-b.mp4

# C: penutup
"$FF" -ss 232.0333 -i out/full-explainer.mp4 -r 30 -c:v libx264 -crf 20 \
  -pix_fmt yuv420p -c:a aac -b:a 192k -ar 48000 -ac 2 -y out/final/part-c.mp4

printf "file 'part-a.mp4'\nfile 'part-b.mp4'\nfile 'part-c.mp4'\n" > out/final/list.txt
"$FF" -f concat -safe 0 -i out/final/list.txt -c copy -y out/uts-skincare-store-final.mp4
```

Terakhir, buat ulang subtitle:

```bash
python scripts/make_srt.py
```

> Catatan: ffmpeg bawaan Remotion menolak filter bernilai tunggal seperti
> `fps=30` atau `setsar=1`. Pakai opsi output `-r 30` dan filter `scale=W:H` saja.

---

## 6. Checklist sebelum submit

- [x] Bagian pembuka menyebut nama, NIM, kelas, judul aplikasi
- [x] Masalah dan pengguna dijelaskan
- [x] Kebutuhan dan prioritas fitur dijelaskan
- [x] Rancangan: user flow, sitemap, wireframe
- [x] Demo prototype berjalan, lebih dari 3 halaman terhubung
- [x] Form tervalidasi dengan pesan error yang terlihat
- [x] Rencana teknis dan penutup
- [x] Durasi di bawah 10 menit (6:15)
- [ ] Video diunggah ke YouTube/Drive, akses tidak privat
- [ ] Tautan video ditempel di README dan formulir E-Learning
