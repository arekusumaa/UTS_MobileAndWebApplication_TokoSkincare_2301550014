# Tabel Uji Login — Minggu 9

**Project Firebase**: `toko-skincare-fec17` (Spark) · **Penyedia**: Email/Password · **Target**: Chrome
**Tanggal uji**: 9 November 2026 · **Cara uji**: `build/web` disajikan di `http://127.0.0.1:8137/`, dikendalikan Chrome headless melalui `playwright-core` (klik mouse dan ketikan keyboard sungguhan, bukan manipulasi DOM).
**Hasil ringkas**: **9 kasus / 9 SESUI / 0 TIDAK SESUAI**.

Hasil mentah: [hasil-uji.json](hasil-uji.json) · Screenshot: [bukti/](bukti/) · Script: `video/scripts/uji-login-m9.js`

## Lima kasus wajib modul

| # | Kasus uji | Input | Hasil yang diharapkan | Hasil nyata | Status | Bukti |
|---|---|---|---|---|---|---|
| 1 | Login benar | `rina@mail.com` / `123456` | Halaman Utama tampil | Beranda tampil, sapaan "Halo, Rina Simulasi!", URL `#/beranda` | ✅ SESUI | [05-login-berhasil.png](bukti/05-login-berhasil.png) |
| 2 | Password salah | `rina@mail.com` / `salah123` | `Email atau password salah` | `Email atau password salah` (banner merah menetap) | ✅ SESUI | [03-password-salah.png](bukti/03-password-salah.png) |
| 3 | Email tidak valid | `bukan-email` / `123456` | `Format email belum benar` | `Format email belum benar`, muncul sebelum request dikirim | ✅ SESUI | [02-email-tidak-valid.png](bukti/02-email-tidak-valid.png) |
| 4 | Kolom kosong | — (tekan Masuk) | Kedua kolom menampilkan pesan | `Email wajib diisi` + `Password wajib diisi` | ✅ SESUI | [01-kolom-kosong.png](bukti/01-kolom-kosong.png) |
| 5 | Daftar dengan email terpakai | `Rina Lagi` / `rina@mail.com` / `123456` | `Email sudah terdaftar. Silakan masuk.` | `Email sudah terdaftar. Silakan masuk.` | ✅ SESUI | [04-email-terpakai.png](bukti/04-email-terpakai.png) |

## Kasus tambahan (perlindungan halaman & sesi)

| # | Kasus uji | Input | Hasil yang diharapkan | Hasil nyata | Status | Bukti |
|---|---|---|---|---|---|---|
| 0 | Akses awal tanpa login | Buka `/` | Halaman Masuk tampil, halaman utama terlindungi | Redirect ke `#/login`, form Masuk tampil | ✅ SESUI | [00-halaman-masuk.png](bukti/00-halaman-masuk.png) |
| 6 | Sesi setelah refresh | F5 pada Beranda | Tetap masuk di Halaman Utama | Beranda tetap tampil, URL `/beranda` | ✅ SESUI | [06-sesi-setelah-refresh.png](bukti/06-sesi-setelah-refresh.png) |
| 7 | Tombol Keluar | Klik ikon Keluar di app bar Beranda | Kembali ke Halaman Masuk | Kembali ke `#/login` tanpa `Navigator` | ✅ SESUI | [07-setelah-keluar.png](bukti/07-setelah-keluar.png) |
| 8 | Akun admin tetap terjangkau | `admin@skincare.id` / `123456` | Menu Dashboard Admin tampil di halaman Akun | Halaman Akun menampilkan badge Admin + menu Dashboard Admin | ✅ SESUI | [08-akun-admin.png](bukti/08-akun-admin.png) |

## Bukti pendukung alur Daftar

| Bukti | Keterangan |
|---|---|
| [09-form-daftar.png](bukti/09-form-daftar.png) | Mode Daftar pada satu halaman yang sama: Nama Lengkap, Email, Password, Ulangi Password |
| [10-pendaftaran-admin.png](bukti/10-pendaftaran-admin.png) | Pendaftaran akun simulasi admin berhasil, langsung masuk ke aplikasi |

Akun simulasi dibuat sungguhan dengan `createUserWithEmailAndPassword`, sehingga **muncul di Authentication > Users pada Firebase Console**. Nama disimpan sebagai `displayName` (`updateDisplayName`) agar halaman Akun bisa menampilkannya tanpa Firestore.

## Terjemahan kode `FirebaseAuthException`

Diimplementasikan pada `lib/core/utils/validasi_auth.dart::pesanKesalahanAuth` dan diuji oleh 3 unit test.

| `e.code` | Keadaan | Pesan untuk pengguna |
|---|---|---|
| `invalid-credential` / `wrong-password` / `user-not-found` | Email tidak terdaftar atau password salah | Email atau password salah |
| `invalid-email` | Format email ditolak | Format email belum benar |
| `email-already-in-use` | Mendaftar dengan email terpakai | Email sudah terdaftar. Silakan masuk. |
| `weak-password` | Password terlalu pendek | Password terlalu lemah, minimal 6 karakter |
| `too-many-requests` | Terlalu banyak percobaan | Terlalu banyak percobaan. Coba lagi nanti. |
| `network-request-failed` | Koneksi gagal | Tidak dapat terhubung. Periksa koneksi internet. |
| `operation-not-allowed` | Penyedia belum diaktifkan | Login email/password belum diaktifkan di Firebase Console |
| `user-disabled` | Akun dinonaktifkan | Akun ini dinonaktifkan. Hubungi administrator. |
| kode lain | — | Terjadi kesalahan. Silakan coba lagi. |

**Mengapa pesan untuk `user-not-found` dan `wrong-password` disamakan?**
Project Firebase baru mengaktifkan *email enumeration protection*, sehingga keduanya sama-sama kembali sebagai `invalid-credential`. Menyamakan pesan mencegah orang lain menebak alamat email mana yang sudah terdaftar. Ini sesuai prinsip yang dijelaskan modul dan sudah diverifikasi pada kasus 2.

## Catatan hasil console browser

Selama uji muncul 3 baris `Failed to load resource: 400`. Ini **bukan bug aplikasi**: permintaan `signInWithEmailAndPassword` dengan password salah, `createUserWithEmailAndPassword` dengan email yang sudah terpakai, dan satu percobaan duplikat memang ditolak Firebase dengan HTTP 400. Aplikasi menangkap `FirebaseAuthException` dan menampilkan pesan yang benar ke pengguna (kasus 2 dan 5 SESUI).

## Cara mengulang uji

```bash
# Terminal 1 — sajikan build web
cd D:\dev\tokoskincare\build\web
python -m http.server 8137 --bind 127.0.0.1

# Terminal 2
cd D:\dev\tokoskincare\video
node scripts/uji-login-m9.js
```

Script bersifat **idempoten**: bila akun simulasi sudah ada, pesan `email-already-in-use` diterima sebagai kondisi siap dan uji tetap dilanjutkan. Hasil ditulis ke `video/out/m9/hasil-uji.json` lalu disalin ke `docs/minggu-09/hasil-uji.json`.
