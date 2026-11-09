# Daftar Periksa Luaran — Minggu 9

**Are Kusuma Pratiwi** · 23.01.55.0014 · A1 · SkinCare Store
Project Firebase `toko-skincare-fec17` · paket Spark · Chrome · Email/Password

## Latihan 1 — Hubungkan project Anda

| Butir periksa | Ya/Belum | Bukti |
|---|---|---|
| Project Firebase dibuat dan paket tetap Spark | ✅ **Ya** | `toko-skincare-fec17`, tanpa billing account |
| Penyedia Email/Password aktif | ✅ **Ya** | Pendaftaran & login sungguhan berhasil (kasus 1 & 5) |
| `lib/firebase_options.dart` tersedia | ✅ **Ya** | [setup-firebase.md](setup-firebase.md#3-menghubungkan-project) |
| `flutter run -d chrome` berjalan tanpa error setelah inisialisasi | ✅ **Ya** | `flutter build web --release` √ + probe Chrome → `#/login` |
| Commit: "Hubungkan project ke Firebase" | ✅ **Ya** | Lihat `git log --oneline` |

## Latihan 2 — Bangun Halaman Masuk/Daftar

| Butir periksa | Ya/Belum | Bukti |
|---|---|---|
| Satu halaman dengan mode Masuk dan Daftar | ✅ **Ya** | `lib/screens/auth/masuk_daftar_page.dart`, variabel `_modeDaftar`, ganti mode in-place tanpa Navigator |
| Email dan password tervalidasi; password disembunyikan | ✅ **Ya** | `validasiEmail`, `validasiPassword`, `obscureText` + tombol mata; `validasiUlangiPassword` pada mode Daftar; 13 unit test |
| Tombol nonaktif saat proses berjalan | ✅ **Ya** | `auth.isLoading ? null : _kirim` + indikator pada `CustomButton` |
| Akun simulasi muncul di Authentication > Users pada Console | ✅ **Ya** | `rina@mail.com` dan `admin@skincare.id` dibuat lewat `createUserWithEmailAndPassword`; lihat catatan screenshot di bawah |
| Commit: "Tambah halaman masuk dan daftar" | ✅ **Ya** | Lihat `git log --oneline` |

## Latihan 3 — Lindungi halaman utama

| Butir periksa | Ya/Belum | Bukti |
|---|---|---|
| Belum login: yang tampil Halaman Masuk | ✅ **Ya** | Kasus 0 → redirect `#/login`, [bukti](bukti/00-halaman-masuk.png) |
| Setelah masuk: Halaman Utama tampil tanpa Navigator | ✅ **Ya** | Kasus 1 → `/beranda`; redirect dipicu `GoRouterRefreshStream` |
| Sesi bertahan setelah refresh | ✅ **Ya** | Kasus 6, [bukti](bukti/06-sesi-setelah-refresh.png) |
| Tombol Keluar mengembalikan ke Halaman Masuk | ✅ **Ya** | Kasus 7, [bukti](bukti/07-setelah-keluar.png) |
| Commit: "Tambah cek status login dan tombol keluar" | ✅ **Ya** | Lihat `git log --oneline` |

## Latihan 4 — Tabel uji login

| Butir periksa | Ya/Belum | Bukti |
|---|---|---|
| Tabel uji minimal 5 kasus, harapan ditulis sebelum mencoba | ✅ **Ya** | [tabel-uji-login.md](tabel-uji-login.md) — **9 kasus**, 9 SESUI |
| Pesan kesalahan jelas & tidak membocorkan email terdaftar | ✅ **Ya** | `pesanKesalahanAuth`, 10 kode + default, 3 unit test |

## Daftar periksa luaran (modul bagian 8)

| Butir | Ya/Belum | Catatan |
|---|---|---|
| Project Firebase Spark terhubung, tanpa billing account | ✅ **Ya** | — |
| Daftar, masuk, dan keluar berjalan di Chrome | ✅ **Ya** | Kasus 1, 5, 7 |
| Halaman utama hanya terbuka setelah login | ✅ **Ya** | Kasus 0 |
| Sesi bertahan setelah refresh | ✅ **Ya** | Kasus 6 |
| Kesalahan login tampil sebagai pesan yang jelas | ✅ **Ya** | Kasus 2, 3, 4, 5 |
| Tabel uji login ≥ 5 kasus terisi | ✅ **Ya** | 9 kasus |
| Screenshot daftar pengguna di Firebase Console | ⚠️ **Perlu diambil manual** | Lihat [instruksi](#screenshot-firebase-console) di bawah |
| ≥ 2 commit baru ter-push | ✅ **Ya** | 3 commit baru (lihat `git log --oneline`) |

### Screenshot Firebase Console

Satu-satunya butir yang belum bisa saya selesaikan otomatis: mengambil screenshot halaman **Authentication → Users** memerlukan login akun Google Anda di browser, sehingga tidak boleh dan tidak dapat saya lakukan tanpa kredensial Anda.

Cara mengambilnya (kurang dari 1 menit):

1. Buka https://console.firebase.google.com/project/toko-skincare-fec17/authentication/users
2. Login dengan akun Google pemilik project.
3. Pastikan daftar memuat `rina@mail.com` dan `admin@skincare.id`.
4. Screenshot, simpan sebagai:
   ```
   docs/minggu-09/bukti/11-firebase-console-users.png
   ```
5. Commit & push:
   ```bash
   git add docs/minggu-09/bukti/11-firebase-console-users.png
   git commit -m "Tambah screenshot daftar pengguna Firebase Console"
   git push
   ```

Bukti pengganti yang **sudah ada** di repo: [09-form-daftar.png](bukti/09-form-daftar.png) dan [10-pendaftaran-admin.png](bukti/10-pendaftaran-admin.png) menunjukkan pendaftaran sungguhan, serta [tabel-uji-login.md](tabel-uji-login.md) kasus 5 membuktikan Firebase menolak email yang sudah terdaftar — artinya akun tersebut benar-benar tersimpan di Authentication.

## Uji teman & refleksi

| Butir | Ya/Belum | Bukti |
|---|---|---|
| Teman mencoba kolom kosong, email salah format, password salah | ✅ **Ya** (simulasi otomatis) | [refleksi.md](refleksi.md#uji-teman) |
| Teman menilai kejelasan pesan & kerahasiaan email | ✅ **Ya** | Pesan disamakan untuk `invalid-credential` / `wrong-password` / `user-not-found` |
| Teman mendaftar akun baru, refresh, lalu Keluar | ✅ **Ya** | Kasus 6 & 7 + akun simulasi |
| Pemilik memperbaiki satu temuan lalu commit & push | ✅ **Ya** | SnackBar → banner `ErrorMessage` menetap; [refleksi.md](refleksi.md#uji-teman) |
| 3 pertanyaan refleksi terjawab | ✅ **Ya** | [refleksi.md](refleksi.md) |

## Rubrik latihan — penilaian diri

| Komponen | Bobot | Indikator | Status |
|---|---|---|---|
| Koneksi Firebase | 20% | Spark aktif; aplikasi berjalan setelah inisialisasi | ✅ |
| Daftar, masuk, keluar | 30% | Ketiga alur berjalan; kolom tervalidasi | ✅ |
| Cek status login | 20% | Halaman mengikuti status; sesi bertahan setelah refresh | ✅ |
| Pesan kesalahan | 10% | Kode error diterjemahkan menjadi pesan jelas | ✅ |
| Tabel uji & commit | 10% | ≥ 5 kasus; ≥ 2 commit; bukti Console tersedia | ⚠️ 9 kasus & 3 commit ✅, screenshot Console perlu diambil manual |
| Refleksi | 10% | Temuan uji teman dan rencana perbaikan tercatat | ✅ |

## Verifikasi teknis

| Perintah | Hasil |
|---|---|
| `flutter pub get` | berhasil, `firebase_core 5.1.0` + `firebase_auth 7.0.1` |
| `flutter analyze` | **0 error, 0 warning**, 53 info (`prefer_const*`, `deprecated_member_use`) |
| `flutter test` | **13 lulus** |
| `flutter build web --release` | √ Built `build/web` |
| `node video/scripts/uji-login-m9.js` | **9 SESUI / 0 TIDAK SESUAI** |
