# Minggu 9 — Menghubungkan Firebase dan Login Email/Password

**SkinCare Store** · Mobile and Web Application Development · Ganjil 2026/2027

| Identitas | Isian |
|---|---|
| Nama / NIM | Are Kusuma Pratiwi / 23.01.55.0014 |
| Kelas | A1 |
| Judul aplikasi | SkinCare Store |
| Repository GitHub | https://github.com/arekusumaa/UTS_MobileAndWebApplication_TokoSkincare_2301550014 |
| Nama project Firebase | `toko-skincare-fec17` |
| Paket | **Spark** (tanpa billing account) |
| Penyedia login | **Email/Password** saja |
| Target | **Chrome** (`flutter run -d chrome` / `flutter build web --release`) |
| Tanggal pengerjaan | 9 November 2026 |

## Ringkasan hasil

Aplikasi yang sebelumnya memakai data simulasi di memori kini **mengenali penggunanya lewat Firebase Authentication**. Data produk, keranjang, dan pesanan masih berupa data simulasi (belum memakai Firestore) — sesuai batas pertemuan ini dan menjadi pekerjaan Minggu 10.

Yang sudah berjalan dan diuji sungguhan di Chrome dengan project Firebase asli:

- `Firebase.initializeApp()` dipanggil dan ditunggu sebelum `runApp`.
- **Satu halaman `MasukDaftarPage` melayani dua mode** (`_modeDaftar`): Masuk dan Daftar. Rute `/login` dan `/register` tetap ada agar sitemap UTS dan video demo tidak berubah.
- `createUserWithEmailAndPassword`, `signInWithEmailAndPassword`, `signOut` lewat `AuthProvider`.
- Validasi `Form` + `GlobalKey` + `TextFormField` + `autovalidateMode`, password `obscureText`, tombol nonaktif saat proses, `mounted`/disposed guard.
- **Auth gate** `StreamBuilder<User?>` pada `authStateChanges()` + `GoRouterRefreshStream` untuk redirect. Tidak ada `Navigator` di kode login.
- Sesi **bertahan setelah refresh**; tombol **Keluar** di app bar Beranda dan Dashboard Admin.
- 10 kode `FirebaseAuthException` diterjemahkan ke pesan Bahasa Indonesia; `invalid-credential`, `wrong-password`, `user-not-found` sengaja disamakan (perlindungan enumerasi email).
- `flutter analyze`: **0 error, 0 warning** (53 info gaya). `flutter test`: **13 lulus**. `flutter build web --release`: **berhasil**.
- **9 kasus uji integrasi** di Chrome: **9 SESUI, 0 TIDAK SESUAI**.

## Daftar isi berkas

| Berkas | Isi |
|---|---|
| [setup-firebase.md](setup-firebase.md) | Langkah setup Console, dependency, `firebase_options.dart`, inisialisasi, keamanan, troubleshooting |
| [tabel-uji-login.md](tabel-uji-login.md) | Tabel uji 9 kasus (harapan vs hasil nyata) + bukti screenshot |
| [refleksi.md](refleksi.md) | Jawaban 3 pertanyaan refleksi, uji teman, satu temuan yang diperbaiki |
| [daftar-periksa.md](daftar-periksa.md) | Checklist Latihan 1–4 dan daftar periksa luaran |
| [hasil-uji.json](hasil-uji.json) | Hasil mentah uji integrasi (dari `video/scripts/uji-login-m9.js`) |
| [bukti/](bukti/) | 11 screenshot halaman Masuk/Daftar/Beranda/Keluar |

## Peta kode

| File | Peran |
|---|---|
| `lib/firebase_options.dart` | `DefaultFirebaseOptions.currentPlatform` → konfigurasi web |
| `lib/main.dart` | `WidgetsFlutterBinding.ensureInitialized()` → `await Firebase.initializeApp(...)` → `runApp` |
| `lib/screens/auth/cek_status_login.dart` | `StreamBuilder<User?>` gerbang autentikasi (padanan `home: CekStatusLogin()`) |
| `lib/router/go_router_refresh_stream.dart` | Memicu ulang redirect GoRouter saat status login berubah |
| `lib/router/app_router.dart` | `_halamanPublik = {'/login','/register'}` + redirect otorisasi |
| `lib/screens/auth/masuk_daftar_page.dart` | Satu halaman, dua mode, form tervalidasi |
| `lib/screens/auth/login_screen.dart` / `register_screen.dart` | Pembungkus tipis untuk dua rute lama |
| `lib/core/utils/validasi_auth.dart` | `validasiEmail`, `validasiPassword`, `validasiUlangiPassword`, `pesanKesalahanAuth` |
| `lib/providers/auth_provider.dart` | Operasi Firebase Auth + `authStateChanges` + pemetaan role sementara |
| `lib/widgets/common/logout_button.dart` | Tombol Keluar bersama (Beranda + Dashboard Admin) |
| `test/validasi_auth_test.dart` | 13 unit test validasi & terjemahan kode error |

## Cara menjalankan

```bash
cd D:\dev\tokoskincare
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
# atau
flutter build web --release
```

Untuk mengulang uji integrasi (memakai Chrome headless yang dibundel Remotion):

```bash
cd build/web && python -m http.server 8137 --bind 127.0.0.1
# terminal lain:
cd video && node scripts/uji-login-m9.js
```

Akun simulasi yang dipakai pengujian (password **bukan** password asli, hanya untuk praktikum):

| Email | Peran | Keterangan |
|---|---|---|
| `rina@mail.com` | Pelanggan | Dibuat lewat halaman Daftar, tersimpan di Firebase Authentication |
| `admin@skincare.id` | Admin | Dibuat agar 4 halaman admin tetap dapat dibuka; role dipetakan sementara di `kAdminEmail` |

Password simulasi: `123456`.

> Catatan batas pertemuan: pemetaan admin lewat konstanta email **bersifat sementara**. Pada Minggu 10 role akan dibaca dari dokumen `users/{uid}` di Firestore.

## Yang masih harus dilakukan manual

1. **Screenshot `Authentication > Users` di Firebase Console** — butuh login akun Google Anda, tidak dapat diambil otomatis. Lihat instruksi di [daftar-periksa.md](daftar-periksa.md#screenshot-firebase-console).
2. **Uji teman langsung di kelas** — 3 skenario ada di [refleksi.md](refleksi.md#uji-teman).
3. Push commit terakhir (sudah dilakukan, lihat `git log`).
