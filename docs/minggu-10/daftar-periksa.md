# Daftar Periksa Minggu 10 — Cloud Firestore

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
| 12 | Profil kulit terhubung | Kontrak, konverter, Rules, dan unit test | ✅ |
| 13 | Pesanan terhubung | Kontrak + query `where('uid', ...)` + Rules | ✅ |
| 14 | Role admin dari Firestore | `users/{uid}.role`, bukan `kAdminEmail` | ✅ |
| 15 | Security Rules aman | `firestore.rules` (default deny, tanpa `if true`) ter-deploy | ✅ |
| 16 | Rules diuji ke server | 13/13 SESUI | ✅ |
| 17 | `firestore.indexes.json` | Kosong & ter-deploy (tidak butuh composite index) | ✅ |
| 18 | `firebase.json` diperbarui | Referensi `rules` + `indexes` | ✅ |
| 19 | `flutter analyze` | 0 error, 0 warning | ✅ |
| 20 | `flutter test` | 24/24 lulus | ✅ |
| 21 | `flutter build web --release` | Berhasil | ✅ |
| 22 | Uji integrasi Chrome | 8/8 SESUI, tanpa console error | ✅ |
| 23 | Dokumentasi modul | `docs/minggu-10/` (7 berkas + JSON hasil uji + screenshot) | ✅ |
| 24 | Skrip pendukung | `promote_admin.py`, `uji_rules.py`, `verifikasi_data.py` | ✅ |
| 25 | Branch terpisah dari UTS | `minggu-10-firestore`, `main` tetap bersih | ✅ |

---

## Yang masih perlu dilakukan manual (di luar kode)

- [ ] Ambil screenshot **Firestore Console → Data** yang memperlihatkan 5
      collection dan simpan ke `docs/minggu-10/bukti/10-firestore-console.png`.
- [ ] Ambil screenshot **Firestore Console → Rules** yang memperlihatkan aturan
      ter-deploy → `11-firestore-rules-console.png`.
- [ ] Bila dosen meminta presentasi, siapkan narasi singkat dari
      [`refleksi.md`](refleksi.md) dan [`tabel-uji.md`](tabel-uji.md).

## Catatan untuk penguji

- UTS **tidak mewajibkan** Firestore; brief masih mengizinkan data simulasi.
  Pekerjaan ini adalah pengembangan lanjutan setelah UTS.
- Akun: `admin@skincare.id` / `rina@mail.com`, password keduanya `123456`.
- Jika products kosong, login sebagai **admin** sekali untuk memicu auto-seed.
- Bila login pelanggan belum pernah dilakukan, dokumen `users/{uid}-nya`
  dibuat otomatis pada login pertama.
