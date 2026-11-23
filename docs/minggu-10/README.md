# Minggu 10 — Cloud Firestore: Collection, Tambah & Tampilkan Data

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

### Pembaruan sesuai modul resmi

Setelah `modul-minggu-10-firestore.docx`, `materi-ajar-minggu-10-firestore.pptx`,
dan video panduan dibaca, lapisan **Create & Read** ditambahkan agar benar-benar
mengikuti bentuk yang diminta modul:

| Butir modul | Implementasi |
| --- | --- |
| `lib/services/layanan_firestore.dart` | `LayananToko` + `LayananFirestore` (`.snapshots()`) + `LayananMemori` (widget test) |
| `StreamBuilder` tiga keadaan | `StreamKeadaan<T>` dipakai Beranda & Riwayat Pesanan; Daftar Produk pakai `StreamBuilder` langsung |
| Aturan bisnis sebelum Create | `cekAturanPesanan()` — cek stok dari server + tolak pesanan identik yang masih `Menunggu` |
| Create & Read (modul resmi) | `skin_profiles` dan `orders` diisi lewat form |
| Lanjutan CRUD produk admin | Tombol **+ Tambah Produk**, ikon **Edit**/**Hapus** di Kelola Produk — menulis/delete `products` di Firestore (hanya admin) |
| Tabel uji ≥5 kasus | **10 kasus, 10/10 SESUI** di [`tabel-uji.md`](tabel-uji.md) bagian 5; tambahan **5/5** CRUD di bagian 6 |

Pemetaan lengkap butir modul ada di [`modul-resmi.md`](modul-resmi.md).

**Ringkasan verifikasi terakhir:** `flutter analyze` 0 error/0 warning ·
`flutter test` **59/59** · `flutter build web --release` berhasil ·
uji Rules **13/13** · integrasi migrasi **8/8** · integrasi modul resmi
**10/10 SESUI** · integrasi CRUD produk **5/5 SESUI**, tanpa console error.

---

## Daftar isi berkas

| Berkas | Isi |
| --- | --- |
| [`modul-resmi.md`](modul-resmi.md) | **Pemetaan butir modul resmi** (DOCX/PPTX/video) → implementasi, Create/Read, 3 keadaan stream, bukti |
| [`setup-firestore.md`](setup-firestore.md) | Langkah mengaktifkan API, membuat database, deploy rules, menaikkan admin |
| [`struktur-database.md`](struktur-database.md) | Skema 5 collection + contoh dokumen |
| [`keputusan-keamanan.md`](keputusan-keamanan.md) | Alasan tiap aturan, matriks akses, batasan yang disadari |
| [`perubahan-kode.md`](perubahan-kode.md) | Arsitektur cache + snapshot, suntikan dependensi, daftar file |
| [`tabel-uji.md`](tabel-uji.md) | 50 unit/widget test, 13 uji Rules, 8 + 10 uji integrasi Chrome, tabel 10 kasus resmi |
| [`refleksi.md`](refleksi.md) | Refleksi pengerjaan + **jawaban 3 pertanyaan refleksi modul** |
| [`daftar-periksa.md`](daftar-periksa.md) | Checklist 44 butir Definition of Done |
| [`isi-firestore.json`](isi-firestore.json), [`bukti/`](bukti/) | Isi database & 16 screenshot aplikasi + 1 gambar isi collection |

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
┌─ Jalur A: lapisan modul resmi (Create & Read, StreamBuilder) ──────────┐
│  Beranda / Daftar Produk / Riwayat Pesanan / Checkout                   │
│       ↓ context.read<LayananToko>() atau parameter `layanan`             │
│  LayananFirestore ── products.snapshots(), orders.where(uid), users/{uid}│
│  LayananMemori    ── versi tanpa Firebase untuk 12 widget test           │
│  cekAturanPesanan() → tambahPesanan() → orders/{id}                      │
└────────────────────────────────────────────────────────────────────────┘

┌─ Jalur B: lapisan migrasi (kontrak repository sinkron) ────────────────┐
│  Provider (Product / Cart / Order / SkinProfile / Auth)                 │
│       ↓                                                                 │
│  AppRepositories ── firestore() ──▶ FirestoreDataSource                 │
│       │                              ├── cache lokal (List/Map)          │
│       │                              ├── snapshots() 5 collection        │
│       │                              └── write async + optimistic update │
│       └── mock() ──▶ Mock*Source (UTS / test)                            │
│                        ↑                                                 │
│                   DataSync.berubah() → notifyListeners() → UI segar       │
└────────────────────────────────────────────────────────────────────────┘
```

Dua jalur sengaja hidup berdampingan: **Jalur B** menjaga 15 halaman Minggu 6/7
tetap utuh tanpa menulis ulang kontrak menjadi `Future`/`Stream`, sedangkan
**Jalur A** memenuhi ketentuan modul bahwa pembacaan realtime harus memakai
`StreamBuilder` + `.snapshots()` dan UI tidak boleh menyentuh Firestore langsung.
Detail ada di [`perubahan-kode.md`](perubahan-kode.md) dan
[`modul-resmi.md`](modul-resmi.md).
