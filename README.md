# SkinCare Store

Aplikasi toko skincare dengan pengingat PAO (Period After Opening) dan filter berdasarkan tipe kulit. Proyek individu MK Mobile and Web Application Development.

## Identitas

- **Nama:** Are Kusuma Pratiwi
- **NIM:** 23.01.55.0014
- **Kelas:** A1 / A2DLC
- **Mata Kuliah:** Mobile and Web Application Development
- **Semester:** Ganjil 2026/2027

## Deskripsi Singkat

SkinCare Store membantu pengguna menemukan produk skincare yang cocok untuk tipe kulitnya. Pengguna dapat mengisi profil kulit (tipe kulit, concern, alergi), menjelajah katalog produk, memesan produk, dan memantau status pesanan. Setiap produk dilengkapi informasi kandungan aktif dan PAO. Tersedia pula dashboard admin untuk mengelola produk dan pesanan.

## Teknologi

- Flutter + Dart (dijalankan di Chrome / web)
- Provider (state management)
- GoRouter (navigasi)
- **Firebase Authentication 7.0.1 + firebase_core 5.1.0** (login Email/Password, Minggu 9 — paket Spark)
- Material 3 (warna primer #D95778)
- Mock data untuk produk/keranjang/pesanan (Firestore menyusul di Minggu 10)

## Tautan

- Desain Figma: https://www.figma.com/design/qVTUEcTMfDeced9ggBp90d/-2301550014--%E2%80%93--SkinCareStore--%E2%80%93-Wireframe?node-id=0-1&t=fjQwAe677ezcqBnl-1
- Video Guideline Dosen: https://youtu.be/zX4AaqMxp5I
- Video UTS (lengkap 6:15): [`video/out/uts-skincare-store-final.mp4`](video/out/uts-skincare-store-final.mp4)
- Proposal UTS: [`docs/uts/proposal-uts-skincare-store.docx`](docs/uts/proposal-uts-skincare-store.docx)
- **Laporan Minggu 9 (Firebase Login)**: [`docs/minggu-09/README.md`](docs/minggu-09/README.md)

## Video UTS

Video presentasi UTS berdurasi **6 menit 15 detik** (1920×1080, 30 fps, narasi
Bahasa Indonesia, subtitle `.srt`), berisi enam bagian sesuai brief:

| Waktu | Bagian |
|-------|--------|
| 0:00 | **Pembuka** — nama, NIM, kelas, judul aplikasi |
| 0:17 | **Masalah & pengguna** — 4 pain point, persona Rina + admin |
| 2:01 | **Kebutuhan & prioritas fitur** — 15 halaman, 5 fitur Must, yang di-exclude |
| 2:59 | **Rancangan** — user flow, sitemap, wireframe Figma → implementasi Flutter |
| 3:52 | **Demo prototype berjalan** — 6 halaman terhubung + form tervalidasi |
| 5:51 | **Rencana teknis & penutup** — tech stack, 5 collection Firestore |

Video dibangun dari dua sumber:

1. **Slide** — [Remotion](https://www.remotion.dev/) + TTS gratis (`edge-tts`,
   suara `id-ID-GadisNeural`), sumber di [`video/src`](video/src).
2. **Demo prototype** — rekaman aplikasi Flutter web yang benar-benar berjalan,
   dikendalikan [Playwright](https://playwright.dev/) (klik mouse dan ketikan
   keyboard sungguhan). Panduan lengkap:
   [`docs/uts/panduan-demo-prototype.md`](docs/uts/panduan-demo-prototype.md).

Cara render ulang: [`video/README.md`](video/README.md).

## Cara Menjalankan

```bash
flutter pub get
flutter run -d chrome
# atau build statis:
flutter build web --release
```

> **Mulai Minggu 9 aplikasi wajib terhubung ke Firebase.** `main.dart` memanggil
> `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
> sebelum `runApp`. Konfigurasi ada di `lib/firebase_options.dart` dan hanya
> diset untuk platform **web** (target praktikum Minggu 9 = Chrome).

Akun simulasi (tersimpan sungguhan di Firebase Authentication, **bukan** lagi
data di memori; password ini sengaja bukan password asli):

| Peran | Email | Password |
|-------|-------|----------|
| Admin | admin@skincare.id | 123456 |
| Pelanggan | rina@mail.com | 123456 |

Akun baru juga bisa dibuat langsung lewat tombol **Daftar** pada halaman Masuk.

## Minggu 9 — Firebase Authentication

Project Firebase `toko-skincare-fec17` (paket **Spark**, tanpa billing) sudah
terhubung. Hanya penyedia **Email/Password** yang diaktifkan; **Firestore belum
dipakai** (jadwal Minggu 10).

| Yang berjalan | Ringkasan |
|---|---|
| Satu halaman dua mode | `lib/screens/auth/masuk_daftar_page.dart` (`_modeDaftar`) — Masuk & Daftar, form tervalidasi, `obscureText`, tombol nonaktif saat proses |
| Auth gate | `StreamBuilder<User?>` pada `authStateChanges()` + `GoRouterRefreshStream` → redirect otomatis, tanpa `Navigator` |
| Halaman publik | Hanya `/login` dan `/register`; 13 halaman lain tertutup bagi yang belum masuk |
| Sesi | Bertahan setelah refresh browser; tombol **Keluar** di app bar Beranda & Dashboard Admin |
| Pesan kesalahan | 10 kode `FirebaseAuthException` diterjemahkan ke Bahasa Indonesia; kode kredensial disamakan agar tidak membocorkan email terdaftar |

**Verifikasi**: `flutter analyze` 0 error/0 warning · `flutter test` 13 lulus ·
`flutter build web --release` berhasil · **9 kasus uji integrasi di Chrome: 9 SESUI**.

Dokumentasi lengkap: [tabel uji 9 kasus](docs/minggu-09/tabel-uji-login.md),
[setup Firebase](docs/minggu-09/setup-firebase.md),
[refleksi](docs/minggu-09/refleksi.md),
[daftar periksa](docs/minggu-09/daftar-periksa.md),
[bukti screenshot](docs/minggu-09/bukti/).

Untuk mengulang uji login otomatis:

```bash
cd build/web && python -m http.server 8137 --bind 127.0.0.1
# terminal lain:
cd video && node scripts/uji-login-m9.js
```

## Screenshot

### Beranda

![Beranda](docs/screenshot-beranda.png)

### Form Checkout dengan Validasi

![Checkout](docs/screenshot-checkout.png)

## Struktur Project

```
lib/
├── core/           # Theme, constants, utils (validators, validasi_auth)
├── data/           # Models, repositories, mock data sources
├── providers/      # State management (Provider) — auth_provider memakai Firebase Auth
├── screens/        # UI (auth, customer, admin)
│   └── auth/       # masuk_daftar_page.dart, cek_status_login.dart
├── widgets/        # Reusable widgets
├── router/         # GoRouter + go_router_refresh_stream.dart
├── firebase_options.dart  # DefaultFirebaseOptions.currentPlatform (web)
└── main.dart       # await Firebase.initializeApp sebelum runApp
```

### Halaman yang Dibangun (15 halaman)

**Pelanggan (11 halaman):**
- Login, Register
- Beranda, Daftar Produk, Detail Produk
- Keranjang, Checkout, Status Pesanan, Riwayat Pesanan
- Profil Kulit, Akun

**Admin (4 halaman):**
- Dashboard Admin, Kelola Produk, Form Produk, Kelola Pesanan

### Navigasi

- **Mobile (<600px)**: Bottom NavigationBar (Beranda, Produk, Keranjang, Akun)
- **Web (>=600px)**: NavigationRail sidebar (responsive)

### Form & Validasi

- **Masuk / Daftar** (satu halaman dua mode, Minggu 9): email + password (format email, minimal 6 karakter); mode Daftar menambah nama lengkap dan ulangi password. Pesan kesalahan Firebase tampil sebagai banner merah yang menetap.
- **Checkout**: nama penerima, telepon, alamat (validasi wajib, format angka, minimal 10 karakter)
- **Profil Kulit**: tipe kulit (ChoiceChip), concern (FilterChip), alergi (text)
- **Form Produk**: nama, kategori (dropdown), harga, stok (angka), kandungan aktif, tipe kulit cocok, PAO (dropdown), manfaat, cara pakai

Semua form menggunakan:
- `GlobalKey<FormState>` untuk validasi
- `autovalidateMode: AutovalidateMode.onUserInteraction`
- Pesan kesalahan spesifik di dekat kolom
- `SnackBar` untuk pesan status berhasil/gagal
- `hideCurrentSnackBar()` sebelum menampilkan SnackBar baru

## Status Pengembangan

- [x] Fase 1 — Layar inti pelanggan (Login, Beranda, Daftar Produk, Detail Produk, Keranjang, Checkout, Status Pesanan)
- [x] Fase 2 — Layar pelengkap (Register, Akun, Profil Kulit, Riwayat Pesanan)
- [x] Fase 3 — Layar admin (Dashboard, Kelola Produk, Form Produk, Kelola Pesanan)
- [x] Fase 4 — Responsive web (bottom nav mobile ↔ sidebar web)
- [x] Fase 5 — Form validasi & state sederhana (Minggu 7)
- [x] Fase 6a — **Firebase Authentication** (Minggu 9): daftar/masuk/keluar, auth gate, sesi, pesan kesalahan
- [ ] Fase 6b — **Cloud Firestore** (Minggu 10): 5 collection `users`, `products`, `skin_profiles`, `orders`, `carts` + Security Rules
