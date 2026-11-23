# Daftar Periksa Minggu 10 — Cloud Firestore (Modul Resmi)

**Modul:** *Cloud Firestore: Collection, Tambah & Tampilkan Data*
**Branch:** `minggu-10-firestore` · **Target:** Chrome · **Paket:** Spark

## A. Migrasi Firestore (pekerjaan awal Minggu 10)

| No | Butir | Bukti | Status |
| --- | --- | --- | --- |
| 1 | `firebase_core` terpasang | `pubspec.yaml` → 5.1.0, `main.dart` → `Firebase.initializeApp` | ✅ |
| 2 | `firebase_auth` terpasang | `pubspec.yaml` → 7.0.1, Minggu 9 | ✅ |
| 3 | `cloud_firestore` terpasang | `pubspec.yaml` → `^7.1.0`, `pubspec.lock` → 7.1.0 | ✅ |
| 4 | FlutterFire CLI dijalankan | `dart pub global run flutterfire_cli:flutterfire configure`, `flutterfire_cli 1.5.0` | ✅ |
| 5 | `lib/firebase_options.dart` valid | Hasil CLI identik (diff kosong) dengan berkas Minggu 9 | ✅ |
| 6 | Database Firestore dibuat | `(default)` @ `asia-southeast2` | ✅ |
| 7 | 5 collection sesuai proposal | `users`, `products`, `skin_profiles`, `orders`, `carts` (diuji unit test) | ✅ |
| 8 | `MockDataSource` → `FirestoreDataSource` | `AppRepositories.firestore()` disuntikkan di `main.dart` | ✅ |
| 9 | Mode simulasi masih tersedia | `--dart-define=PAKAI_MOCK=true` | ✅ |
| 10 | Data produk persisten | 10 dokumen `products`, tampil di Daftar Produk | ✅ |
| 11 | Data keranjang persisten | `carts/{uid}/items/P01`, tetap ada setelah F5 | ✅ |
| 12 | Profil kulit terhubung | 1 dokumen `skin_profiles` dari form | ✅ |
| 13 | Pesanan terhubung | 3 dokumen `orders` dari Checkout | ✅ |
| 14 | Role admin dari Firestore | `users/{uid}.role`, bukan `kAdminEmail` | ✅ |
| 15 | Security Rules aman | `firestore.rules` (default deny, tanpa `if true`) ter-deploy | ✅ |
| 16 | Rules diuji ke server | 13/13 SESUI | ✅ |
| 17 | `firestore.indexes.json` | Kosong & ter-deploy (tidak butuh composite index) | ✅ |
| 18 | `firebase.json` diperbarui | Referensi `rules` + `indexes` | ✅ |
| 19 | Branch terpisah dari UTS | `minggu-10-firestore`, `main` tetap bersih | ✅ |

## B. Butir modul resmi (DOCX / PPTX / video panduan)

| No | Butir modul | Bukti | Status |
| --- | --- | --- | --- |
| 20 | Hanya **Create & Read** (Update/Delete Minggu 11) | `LayananToko` tidak punya operasi update/delete | ✅ |
| 21 | Minimal 3 collection berisi data | 5 collection, [`isi-firestore.json`](isi-firestore.json) | ✅ |
| 22 | `lib/services/layanan_firestore.dart` | `LayananToko` / `LayananFirestore` / `LayananMemori` | ✅ |
| 23 | UI tidak memanggil `FirebaseFirestore.instance` langsung | Injeksi `Provider<LayananToko>.value` di `main.dart` | ✅ |
| 24 | `StreamBuilder` + `.snapshots()` | Daftar Produk, Riwayat Pesanan, Beranda | ✅ |
| 25 | Tiga keadaan `waiting` / `hasError` / kosong | `StreamKeadaan<T>` + 4 widget test | ✅ |
| 26 | Satu `.where()`, sort & filter di Dart | `terapkanFilterProduk()`, `List.sort()`, index kosong | ✅ |
| 27 | **Aturan bisnis sebelum Create** | `cekAturanPesanan()` — stok + anti-duplikat `menunggu` | ✅ |
| 28 | Validasi form sebelum dokumen ditulis | `Form` + `autovalidateMode`, kasus uji #3 | ✅ |
| 29 | Realtime tanpa refresh | Kasus uji #8 (status berubah dari server) | ✅ |
| 30 | Persistensi setelah F5 | Kasus uji #7 | ✅ |
| 31 | Isolasi data antar pengguna | `.where('uid')` + Rules, kasus uji #9 | ✅ |
| 32 | Widget test dengan `LayananMemori` | `test/widget_test.dart` (12 test, tanpa Firebase) | ✅ |
| 33 | Tabel uji **≥5 kasus** harapan vs hasil nyata | [Bagian 5 `tabel-uji.md`](tabel-uji.md) — **10 kasus, 10 SESUI** | ✅ |
| 34 | 3 pertanyaan refleksi dijawab | [Bagian refleksi modul](refleksi.md) | ✅ |
| 35 | Pemetaan modul & bukti | [`modul-resmi.md`](modul-resmi.md) | ✅ |
| 36 | ≥2 commit baru | Lihat `git log` branch `minggu-10-firestore` | ✅ |
| 37 | Screenshot alur aplikasi | `bukti/01…18-*.png` (16 screenshot) | ✅ |
| 38 | Bukti isi collection | `bukti/19-isi-collection.png` (dari REST API, diberi catatan kejujuran) | ✅ |
| 39 | `flutter analyze` | **0 error, 0 warning** (50 info) | ✅ |
| 40 | `flutter test` | **59/59 lulus** | ✅ |
| 41 | `flutter build web --release` | Berhasil | ✅ |
| 42 | Uji Rules / integrasi migrasi / integrasi modul | **13/13 · 8/8 · 10/10 SESUI**, 0 console error | ✅ |
| 43 | Skrip pendukung | `promote_admin.py`, `uji_rules.py`, `verifikasi_data.py`, `uji-firestore-m10.js`, `uji-modul-m10.js`, `buat-bukti-data.js` | ✅ |
| 44 | Dokumentasi `docs/minggu-10/` | 9 berkas Markdown + JSON hasil uji + bukti | ✅ |

---

## Yang masih perlu dilakukan manual (di luar kode)

- [ ] Ambil screenshot **Firebase Console → Firestore Data** yang memperlihatkan
      5 collection → simpan ke
      `docs/minggu-10/bukti/20-firestore-console-data.png`.
- [ ] Ambil screenshot **Firebase Console → Firestore Rules** yang memperlihatkan
      aturan ter-deploy → `docs/minggu-10/bukti/21-firestore-console-rules.png`.
- [ ] Bila dosen meminta presentasi, siapkan narasi singkat dari
      [`refleksi.md`](refleksi.md) dan [`tabel-uji.md`](tabel-uji.md).

> Kedua screenshot Console memerlukan sesi login Google mahasiswa, sehingga
> tidak dapat diotomatisasi dari lingkungan ini. **Jangan** mengklaim
> `19-isi-collection.png` sebagai screenshot Console: gambar itu dirakit dari
> respons Firestore REST API dan sudah memuat catatan tersebut di dalamnya.

## Catatan untuk penguji

- UTS **tidak mewajibkan** Firestore; brief masih mengizinkan data simulasi.
  Pekerjaan ini adalah pengembangan lanjutan setelah UTS, dikerjakan di branch
  terpisah agar `main` tetap mewakili kondisi Minggu 9 / UTS.
- Akun: `admin@skincare.id` / `rina@mail.com`, password keduanya `123456`.
- Jika `products` kosong, login sebagai **admin** sekali untuk memicu auto-seed.
- Token `firebase-tools` bisa kedaluwarsa. Jalankan satu perintah CLI
  terautentikasi (mis. `firebase firestore:databases:list --project …`) sebelum
  `python scripts/uji_rules.py` atau `verifikasi_data.py`.
- `flutter test` memerlukan `NO_PROXY="localhost,127.0.0.1,::1"` di lingkungan
  ber-proxy ini.
