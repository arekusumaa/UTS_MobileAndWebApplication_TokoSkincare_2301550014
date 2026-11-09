# Minggu 10 — Cloud Firestore & Security Rules

**Nama:** Are Kusuma Pratiwi
**NIM:** 23.01.55.0014 · **Kelas:** A1 / A2DLC
**Mata kuliah:** Pengembangan Aplikasi Mobile dan Web — Ganjil 2026/2027
**Aplikasi:** SkinCare Store
**Branch:** `minggu-10-firestore` (branch `main` tetap bersih untuk penilaian Minggu 9 / UTS)
**Project Firebase:** `toko-skincare-fec17` (paket **Spark**, tanpa billing)

---

## Ringkasan

Minggu 9 menyelesaikan **Firebase Authentication**. Minggu 10 mengganti sumber data
simulasi (`Mock*Source`) dengan **Cloud Firestore** sungguhan, lalu memasang
**Security Rules** yang membatasi akses berdasarkan status login dan peran.

| Sebelum (Minggu 9 / UTS) | Sesudah (Minggu 10) |
| --- | --- |
| Data produk, pesanan, profil kulit, keranjang di memori | 5 collection Firestore dengan listener realtime |
| Hilang saat browser di-refresh | Persisten lintas sesi & lintas perangkat |
| Peran admin dari `kAdminEmail` hard-code | Peran dari dokumen `users/{uid}` |
| Tidak ada aturan akses data | `firestore.rules` dengan default-deny |
| `firebase_core` + `firebase_auth` | + `cloud_firestore 7.1.0` |

> Catatan: brief UTS **masih mengizinkan data simulasi**. Pekerjaan ini bersifat
> pengembangan lanjutan, bukan syarat UTS. Mode simulasi tetap tersedia lewat
> `--dart-define=PAKAI_MOCK=true`.

---

## Daftar isi berkas

| Berkas | Isi |
| --- | --- |
| [`setup-firestore.md`](setup-firestore.md) | Langkah mengaktifkan API, membuat database, deploy rules, menaikkan admin |
| [`struktur-database.md`](struktur-database.md) | Skema 5 collection + contoh dokumen |
| [`keputusan-keamanan.md`](keputusan-keamanan.md) | Alasan tiap aturan, matriks akses, batasan yang disadari |
| [`perubahan-kode.md`](perubahan-kode.md) | Arsitektur cache + snapshot, suntikan dependensi, daftar file |
| [`tabel-uji.md`](tabel-uji.md) | Unit test, analisis statis, build, dan uji integrasi Chrome |
| [`refleksi.md`](refleksi.md) | Refleksi pengerjaan |
| [`daftar-periksa.md`](daftar-periksa.md) | Checklist Definition of Done |

---

## Cara menjalankan

```bash
# 1. Dependensi
flutter pub get

# 2. Pastikan aturan keamanan sudah terpasang (sekali saja)
firebase deploy --only firestore:rules,firestore:indexes \
  --project toko-skincare-fec17

# 3. Jadikan akun simulasi sebagai admin (sekali saja)
python scripts/promote_admin.py                # admin@skincare.id / 123456

# 4. Jalankan aplikasi (data Firestore sungguhan)
flutter run -d chrome

# 5. Alternatif: mode data simulasi untuk UTS / screenshot
flutter run -d chrome --dart-define=PAKAI_MOCK=true
```

Akun simulasi yang sudah ada di Firebase Authentication:

| Peran | Email | Password |
| --- | --- | --- |
| Admin | `admin@skincare.id` | `123456` |
| Pelanggan | `rina@mail.com` | `123456` |

Saat **admin pertama kali masuk**, `FirestoreDataSource.seedProductsIfEmpty()`
otomatis mengisi 10 produk contoh dari `MockData` bila collection `products`
masih kosong. Pelanggan tidak memiliki hak tulis produk, sehingga tidak akan
mengisi ulang data.

---

## Alur data singkat

```
UI (15 halaman, tidak diubah)
   ↓  context.watch / context.read
Provider (Product / Cart / Order / SkinProfile / Auth)
   ↓  kontrak repository SINKRON
AppRepositories  ── firestore() ──▶ FirestoreDataSource
   │                                   ├── cache lokal (List/Map)
   │                                   ├── snapshots() realtime (5 collection)
   │                                   └── write async + optimistic update
   └── mock() ──▶ Mock*Source (untuk test & UTS)
                        ↑
                   DataSync.berubah() → notifyListeners() → UI segar
```

Detail ada di [`perubahan-kode.md`](perubahan-kode.md).
