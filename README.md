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
- Material 3 (warna primer #D95778)
- Mock data (Firestore menyusul di Fase 5)

## Tautan

- Desain Figma: https://www.figma.com/design/qVTUEcTMfDeced9ggBp90d/-2301550014--%E2%80%93--SkinCareStore--%E2%80%93-Wireframe?node-id=0-1&t=fjQwAe677ezcqBnl-1
- Video Guideline Dosen: https://youtu.be/zX4AaqMxp5I
- Video UTS (lengkap 6:15): [`video/out/uts-skincare-store-final.mp4`](video/out/uts-skincare-store-final.mp4)
- Proposal UTS: [`docs/uts/proposal-uts-skincare-store.docx`](docs/uts/proposal-uts-skincare-store.docx)

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
```

Akun demo:

| Peran | Email | Password |
|-------|-------|----------|
| Admin | admin@skincare.id | 123456 |
| Pelanggan | rina@mail.com | 123456 |

## Screenshot

### Beranda

![Beranda](docs/screenshot-beranda.png)

### Form Checkout dengan Validasi

![Checkout](docs/screenshot-checkout.png)

## Struktur Project

```
lib/
├── core/           # Theme, constants, utils (validators)
├── data/           # Models, repositories, mock data sources
├── providers/      # State management (Provider)
├── screens/        # UI (auth, customer, admin)
├── widgets/        # Reusable widgets
└── router/         # GoRouter configuration
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

- **Login**: email + password (validasi format, minimal 6 karakter)
- **Register**: nama, email, password, konfirmasi password
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
- [ ] Fase 6 — Firebase (Auth + Firestore)
