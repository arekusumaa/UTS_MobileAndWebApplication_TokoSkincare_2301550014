# Refleksi Individu — Minggu 9

**Are Kusuma Pratiwi** · 23.01.55.0014 · A1 · SkinCare Store

## Pertanyaan 1 — Halaman mana yang boleh dibuka tanpa login? Mengapa?

**Hanya dua halaman: `/login` dan `/register`.** Keduanya sebenarnya adalah satu widget `MasukDaftarPage` dengan dua mode, yang dipetakan ke dua rute agar sitemap UTS dan rekaman demo prototype tetap konsisten.

Implementasinya ada di `lib/router/app_router.dart`:

```dart
static const _halamanPublik = {'/login', '/register'};

redirect: (context, state) {
  final sudahMasuk = FirebaseAuth.instance.currentUser != null;
  final diHalamanPublik = _halamanPublik.contains(state.matchedLocation);
  if (!sudahMasuk && !diHalamanPublik) return '/login';
  if (sudahMasuk && diHalamanPublik) return '/beranda';
  return null;
}
```

Alasannya:

- **Autentikasi = siapa kamu**, dijawab oleh Firebase Authentication. **Otorisasi = boleh melakukan apa**, dijawab oleh redirect di atas. Kalau halaman Masuk/Daftar ikut dilindungi, pengguna tidak punya jalan masuk (lingkaran tanpa akhir).
- **13 halaman sisanya tidak boleh publik** karena semuanya bersifat personal atau operasional: Beranda menampilkan sapaan nama dan rekomendasi berdasar profil kulit; Profil Kulit, Keranjang, Checkout, Status Pesanan, Riwayat Pesanan, dan Akun berisi data milik satu pengguna; 4 halaman Admin (Dashboard, Kelola Produk, Form Produk, Kelola Pesanan) hanya untuk peran admin.
- Redirect juga berlaku **dua arah**: pengguna yang sudah masuk tidak perlu lagi melihat halaman Masuk, jadi dipaksa ke `/beranda`. Ini mencegah tampilan "sudah login tapi masih di form login".
- Yang belum ada di Minggu 9: **pembatasan peran di level data**. Role admin masih dipetakan dari konstanta `kAdminEmail` di `AuthProvider` karena Firestore belum dipakai. Artinya otorisasi saat ini baru sebatas "sudah masuk / belum masuk"; pembatasan "admin / pelanggan" baru benar-benar aman setelah Security Rules dan dokumen `users/{uid}` dibuat pada Minggu 10. Ini saya catat sebagai batas yang jujur, bukan saya klaim sudah selesai.

## Pertanyaan 2 — Kendala saat setup Firebase dan cara mengatasinya

| # | Kendala | Dampak | Cara mengatasi |
|---|---|---|---|
| 1 | Konfigurasi yang saya terima dari Console berbentuk **JavaScript** (`import { initializeApp } from "firebase/app"`, `getAnalytics`, `const firebaseConfig = {...}`) | Tidak bisa ditempel ke Flutter/Dart; `getAnalytics` juga khusus browser JS | Saya petakan ke `lib/firebase_options.dart` berisi `DefaultFirebaseOptions.currentPlatform` → `FirebaseOptions(apiKey:, appId:, messagingSenderId:, projectId:, authDomain:, storageBucket:, measurementId:)`. `getAnalytics` **tidak** dipakai (Minggu 9 tidak membutuhkan Analytics). |
| 2 | FlutterFire CLI (`firebase login` + `flutterfire configure`) butuh Node.js dan `firebase-tools` | Waktu setup lebih lama, risiko `flutterfire` tidak dikenali karena pub cache belum di PATH | Memilih **jalur cadangan: salin manual** sebagaimana diizinkan modul. Hanya platform `web` yang dikonfigurasi karena target pertemuan ini Chrome; platform lain sengaja melempar `UnsupportedError` dengan petunjuk menjalankan CLI lagi. |
| 3 | `flutter test` gagal terhubung karena variabel proxy lingkungan juga menjangkau `localhost` | Test tidak bisa start | Menjalankan dengan `NO_PROXY="localhost,127.0.0.1,::1"` / `no_proxy=...`. Hasil: **13 test lulus**. |
| 4 | Project sudah punya **dua halaman terpisah** (`login_screen.dart`, `register_screen.dart`) sejak Minggu 6, padahal modul minta **satu halaman dua mode** (`_modeDaftar`) | Checklist Latihan 2 belum terpenuhi | Refactor ke `lib/screens/auth/masuk_daftar_page.dart` dengan `_modeDaftar` dan tombol ganti mode in-place (`setState`). Kedua file lama dijadikan pembungkus tipis supaya rute `/login` dan `/register` tetap ada. Setelah refactor: `flutter analyze` 0 error, 13 test lulus, build web berhasil, dan **9 kasus uji integrasi tetap SESUI**. |
| 5 | Aplikasi Flutter web dirender ke `<canvas>`, sehingga tidak ada elemen DOM untuk diklik seperti aplikasi web biasa | Otomatisasi uji di Chrome awalnya tidak menemukan tombol | Mengaktifkan semantics Flutter (`flt-semantics-placeholder`), lalu mencari node `flt-semantics` ber-`role=button` dan mencocokkan `innerText`, dengan heuristic node terkecil + event mouse pada koordinat nyata. Untuk input, memakai `page.keyboard.type` sungguhan — `execCommand` tidak memperbarui state Flutter. |
| 6 | Tautan ke mode Daftar awalnya dicari lewat teks "Belum punya akun" | Klik tidak kena | Teks statis itu bukan node button; yang ber-role `button` adalah teks **"Daftar"**. Script uji diperbaiki ke `klik(page, "Daftar")`. |
| 7 | 3 baris `Failed to load resource: 400` muncul di console saat uji | Terlihat seperti error aplikasi | Ditelusuri: itu respon wajar Firebase untuk password salah dan email duplikat. Aplikasi menangkap `FirebaseAuthException` dan menampilkan pesan yang benar (kasus 2 & 5 SESUI). Dicatat di tabel uji supaya tidak salah dibaca sebagai bug. |

Kendala lain yang **bukan** bagian setup Firebase tetapi sempat menghalangi pengumpulan: GitHub menolak push dengan `GH007 push would publish a private email`. Semua commit sudah ditulis ulang ke `arekusumaa@users.noreply.github.com`, sehingga repo dapat di-push tanpa membuka alamat email pribadi.

## Pertanyaan 3 — Data apa yang harus tersimpan permanen di Firestore pada Minggu 10?

Rencana database sudah saya susun di proposal UTS. Yang **wajib permanen** (hilang saat aplikasi dijalankan ulang karena sekarang masih di memori):

| Collection | Isi | Kenapa harus permanen |
|---|---|---|
| `users/{uid}` | `uid` (dari Firebase Auth), `nama`, `email`, **`role`** (`admin`/`pelanggan`), `createdAt` | Menggantikan pemetaan sementara `kAdminEmail`. Tanpa ini otorisasi peran tidak bisa dipercaya. `uid` dipakai sebagai doc ID agar sinkron dengan Authentication. |
| `skin_profiles/{uid}` | `jenisKulit`, `masalahKulit[]`, `bahanDihindari[]`, `updatedAt` | Profil kulit adalah inti nilai aplikasi (filter & rekomendasi produk). Sekarang hilang tiap refresh. |
| `products/{id}` | `nama`, `kategori`, `harga`, `stok`, `kandunganAktif[]`, `manfaat`, `paoBulan`, `gambarUrl`, `badge stok` | Katalog dikelola admin lewat Form Produk; perubahan harga/stok harus bertahan dan terlihat semua pengguna. |
| `carts/{uid}/items/{productId}` | `productId`, `jumlah`, `subtotal` | Keranjang harus tersimpan lintas sesi/perangkat. Bisa juga `carts/{uid}` dengan array item. |
| `orders/{orderId}` | `orderId`, `uid`, `items[]`, `namaPenerima`, `telepon`, `alamat`, `ongkir`, `total`, `status`, `timeline[]`, `createdAt` | Pesanan dan status pengiriman harus tetap ada setelah checkout, dibaca pelanggan (Riwayat/Status) **dan** admin (Kelola Pesanan). |

Yang **tidak** perlu dipindah ke Firestore: session/token login — itu sudah dikelola otomatis oleh Firebase Authentication SDK. Ini persis pengamatan yang diminta modul: *setelah refresh pengguna tetap masuk, tetapi data yang baru dibuat hilang*, karena sesi disimpan Firebase sedangkan data aplikasi masih di memori.

Persiapan Minggu 10 yang sudah saya siapkan: arsitektur **Repository Pattern** (`MockDataSource` saat ini → `FirestoreDataSource` nanti), sehingga UI dan Provider tidak perlu diubah besar-besaran; serta `firebase.json` dan struktur 5 collection di proposal UTS.

## Uji teman

Modul meminta teman mencoba tiga skenario dan menilai kejelasan pesan. Skenario yang disiapkan (dapat diulang manual di kelas, atau otomatis lewat `video/scripts/uji-login-m9.js`):

| Skenario | Yang dinilai teman | Hasil |
|---|---|---|
| Masuk dengan kolom kosong | Apakah kedua pesan muncul dan jelas? | ✅ `Email wajib diisi` + `Password wajib diisi` |
| Masuk dengan email salah format | Apakah pesan menjelaskan *format*, bukan "gagal"? | ✅ `Format email belum benar` |
| Masuk dengan password salah | Apakah pesan **tidak membocorkan** email mana yang terdaftar? | ✅ `Email atau password salah` (sama untuk email terdaftar maupun tidak) |
| Daftar akun simulasi baru → refresh browser → Keluar | Apakah sesi bertahan dan Keluar benar-benar mengakhiri? | ✅ Kasus 6 & 7 SESUI |

**Satu temuan yang diperbaiki (sesuai instruksi "pemilik memperbaiki satu temuan, lalu commit dan push"):**

> *Temuan*: pesan kesalahan awalnya saya rencanakan memakai `SnackBar` mengikuti potongan kode modul. Saat dicoba berulang kali, SnackBar hilang dalam ±4 detik sehingga teman yang sedang membaca/mencatat pesan keburu kehilangan bukti, dan pesan baru menimpa pesan lama jika tombol ditekan dua kali.
>
> *Perbaikan*: pesan kesalahan Firebase dipindah ke widget **`ErrorMessage`** berupa banner merah yang **menetap** di dalam form, lengkap dengan tombol tutup yang memanggil `AuthProvider.clearError()`. Tetap dipakai `hideCurrentSnackBar()` sebelum SnackBar lain di seluruh aplikasi (warisan Minggu 7), dan `auth.isLoading` menonaktifkan tombol agar tidak ada kiriman ganda. Perbaikan ini masuk commit **"Tambah halaman masuk/daftar, cek status login, dan pesan kesalahan"**.

Catatan kejujuran: uji teman tatap muka belum dilaksanakan karena pengerjaan dilakukan mandiri; yang terdokumentasi di sini adalah **uji otomatis yang mensimulasikan persis tiga skenario modul** plus temuan dari uji mandiri berulang. Saat kelas, teman tinggal menjalankan tiga skenario di atas pada `flutter run -d chrome` dan mengisi penilaian kejelasan pesan.

## Pengayaan (belum dikerjakan, tidak wajib)

`FirebaseAuth.instance.sendPasswordResetEmail(email: email)` untuk fitur lupa password. Sengaja belum ditambahkan agar ruang lingkup Minggu 9 tetap sesuai batas modul.
