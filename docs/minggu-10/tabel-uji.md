# Tabel Uji Minggu 10 — Cloud Firestore

Seluruh pengujian dilakukan terhadap **database sungguhan**
`toko-skincare-fec17` (bukan emulator), dengan rules yang sudah di-deploy.

---

## 1. Verifikasi statis & unit

| No | Pemeriksaan | Perintah | Hasil |
| --- | --- | --- | --- |
| 1 | Analisis statis | `flutter analyze` | **0 error, 0 warning**, 50 info (lint lama: `prefer_const`, depresiasi `withOpacity`) |
| 2 | Unit + widget test | `flutter test --no-pub` | **59/59 lulus** (tambah 5 kasus `tentukanRole` + 5 kasus `MockUserSource`) |
| 3 | Build release | `flutter build web --release` | **Berhasil** (`build/web`, Wasm dry run sukses) |
| 4 | Kompilasi rules | `firebase deploy --only firestore:rules` | `rules file firestore.rules compiled successfully` |
| 5 | Deploy index | `firebase deploy --only firestore:indexes` | `deployed indexes ... successfully` |

Rincian **50 test**:

| Berkas test | Jumlah | Cakupan |
| --- | --- | --- |
| `test/validasi_auth_test.dart` | 13 | Validasi email/password & 10 terjemahan kode `FirebaseAuthException` (Minggu 9) |
| `test/firestore_converters_test.dart` | 11 | Nama 5 collection, round-trip produk, `Timestamp` PAO, toleransi tipe `num`/ISO, role admin & fallback pelanggan, round-trip profil kulit, `productId` keranjang, dokumen keranjang rusak, `uid`/`items`/status pesanan, status tak dikenal |
| `test/layanan_toko_test.dart` | 14 | `tandaKeranjang`, 5 aturan bisnis (kosong / stok / duplikat / selesai / valid), 4 stream realtime & error, 4 filter Dart tanpa composite index |
| `test/widget_test.dart` | 12 | 4 keadaan `StreamKeadaan`, 4 `RiwayatPesananScreen` (kosong / ada data / realtime / error), 4 `DaftarProdukScreen` (waiting / 10 produk / pencarian / error) — semuanya dengan `LayananMemori`, tanpa koneksi Firebase |

---

## 2. Uji Security Rules langsung ke server (13 kasus)

`python scripts/uji_rules.py` meminta **ID token Firebase** untuk akun admin dan
pelanggan, lalu mengirim request REST ke Firestore. Jadi yang diuji adalah
keputusan **server**, bukan sekadar tombol yang disembunyikan di UI.
Hasil mentah: [`hasil-uji-rules.json`](hasil-uji-rules.json).

| No | Kasus | Diharapkan | Aktual | Status |
| --- | --- | --- | --- | --- |
| 1 | Anonim membaca `products` | HTTP 403 | HTTP 403 | SESUI |
| 2 | Pelanggan membaca `products` | HTTP 200 | HTTP 200 | SESUI |
| 3 | Pelanggan membuat produk baru | HTTP 403 | HTTP 403 | SESUI |
| 4 | Pelanggan mengubah **harga** P01 | HTTP 403 | HTTP 403 | SESUI |
| 5 | Pelanggan **menaikkan** stok P01 | HTTP 403 | HTTP 403 | SESUI |
| 6 | Pelanggan mengubah `role` sendiri jadi admin | HTTP 403 | HTTP 403 | SESUI |
| 7 | Pelanggan membaca `carts/{admin}/items` | HTTP 403 | HTTP 403 | SESUI |
| 8 | Pelanggan query semua `orders` tanpa `where(uid)` | HTTP 403 | HTTP 403 | SESUI |
| 9 | Pelanggan membuat order dengan `uid` orang lain | HTTP 403 | HTTP 403 | SESUI |
| 10 | Admin membuat produk | HTTP 200 | HTTP 200 | SESUI |
| 11 | Admin menghapus produk uji | HTTP 200 | HTTP 200 | SESUI |
| 12 | Admin query semua `orders` | HTTP 200 | HTTP 200 | SESUI |
| 13 | Admin membaca `users/{uid}` pelanggan | HTTP 200 | HTTP 200 | SESUI |

**13/13 SESUI.** Dokumen uji `UJI-RULES-001` langsung dihapus pada kasus 11,
sehingga tidak meninggalkan sampah data.

> Catatan: sebelum uji dijalankan, skrip menyiapkan dokumen `users/{pelanggan}`
> memakai token pemilik project (fixture), meniru login pertama pelanggan.

---

## 3. Uji integrasi aplikasi Flutter Web ↔ Firestore (8 kasus)

`cd video && node scripts/uji-firestore-m10.js` pada `build/web` yang disajikan
di `http://127.0.0.1:8137/`. Menggunakan klik mouse dan ketikan keyboard
sungguhan lewat Playwright. Hasil mentah: [`bukti/hasil-uji.json`](bukti/hasil-uji.json),
screenshot di [`bukti/`](bukti/).

| No | Kasus | Diharapkan | Status |
| --- | --- | --- | --- |
| 1 | Buka aplikasi tanpa login | Redirect ke `#/login` | SESUI |
| 2 | Login `admin@skincare.id` | Beranda tampil | SESUI |
| 3 | Role admin terbaca dari `users/{uid}` | Badge **Admin** + menu **Dashboard Admin** | SESUI |
| 4 | Produk terbaca dari `products` | `Glow Cleanser Gel` tampil di Daftar Produk | SESUI |
| 5 | Login `rina@mail.com` | Beranda tampil | SESUI |
| 6 | Detail `P01` dari Firestore | Detail produk tampil | SESUI |
| 7 | Klik **Keranjang** → halaman Keranjang | Ringkasan `Total (N item)` + tombol Checkout | SESUI |
| 8 | Refresh browser (F5) | Keranjang **masih berisi item** (bukan memori) | SESUI |

**8/8 SESUI**, tanpa `console error` / `pageerror` di browser.

Kenapa kasus 7–8 tidak mengecek nama produk? Halaman Keranjang tidak
mengekspos nama produk ke accessibility tree Flutter (hanya `Total (N item)`,
`Checkout`, `Hapus`). Karena itu skrip memakai sinyal ringkasan + tombol, dan
bukti visual ada pada `bukti/06-keranjang-firestore.png` serta
`bukti/07-keranjang-setelah-refresh.png`. Isi dokumen diverifikasi lagi lewat
REST (bagian 4).

---

## 4. Isi database setelah pengujian

`python scripts/verifikasi_data.py` → [`isi-firestore.json`](isi-firestore.json).

| Collection | Isi | Artinya |
| --- | --- | --- |
| `products` | 10 dokumen `P01`–`P10` | Auto-seed admin berhasil, dibaca `.snapshots()` |
| `users` | 2 dokumen | `role: admin` & `role: pelanggan` |
| `skin_profiles` | 1 dokumen | Dibuat lewat form Profil Kulit (kasus uji #1) |
| `orders` | 3 dokumen | Dibuat lewat Checkout; semuanya `menunggu` saat dibuat lalu jadi `diproses` pada uji realtime #8 |
| `carts` | sub-koleksi `carts/{pelanggan}/items/P01` | Keranjang persisten, bukan cache lokal |

Ringkasan visual: [`bukti/19-isi-collection.png`](bukti/19-isi-collection.png)
(dirakit dari respons REST API, bukan screenshot Console).

Contoh dokumen `orders/{id}` hasil Create sungguhan:

```json
{
  "uid": "stjEG021jVXudJIN0uY57wdhoDq1",
  "id": "ORD-20261116-62942",
  "status": "menunggu",
  "total": 55000,
  "items": [{
    "productId": "P01", "quantity": 1,
    "product": { "nama": "Glow Cleanser Gel", "harga": 45000, "...": "..." }
  }],
  "alamat": "Jl. Mawar No. 12, Jakarta Selatan",
  "namaPenerima": "Rina Pratiwi",
  "telepon": "081234567890"
}
```

---

## 5. Tabel uji resmi modul — Create & Tampilkan Data (10 kasus)

Ini adalah tabel **Latihan 4** modul: minimal 5 kasus dengan *harapan* dan
*hasil nyata*. Dijalankan oleh `video/scripts/uji-modul-m10.js` pada aplikasi
Flutter Web yang tersaji di `http://127.0.0.1:8137/`. Setiap kasus diverifikasi
**dua kali**: dari UI (accessibility tree / URL / screenshot) **dan** dari server
Firestore lewat REST API dengan token pemilik project, sehingga bukan sekadar
klaim tampilan.

Hasil mentah: [`bukti/hasil-uji-modul.json`](bukti/hasil-uji-modul.json).

| No | Kasus uji | Harapan | Hasil nyata | Status |
| --- | --- | --- | --- | --- |
| 0 | Login pelanggan (prasyarat) | Beranda tampil | Sapaan `Halo, ...` tampil | SESUI |
| 1 | **Create** `skin_profiles/{uid}` lewat form Profil Kulit | 1 dokumen baru, `tipeKulit='Berminyak'`, `concern=['Jerawat']` | HTTP 200 dari REST; field `tipeKulit` = `Berminyak`; chip kembali terpilih saat halaman dibuka ulang | SESUI |
| 2 | **Read** `products` lewat `StreamBuilder` + `.snapshots()` | 10 produk tampil sesuai isi server | UI `10 produk ditemukan`; server punya 10 dokumen `P01`–`P10` | SESUI |
| 3 | Validasi form Checkout **sebelum** Create | Form kosong ditolak, belum ada dokumen `orders` | Pesan `wajib diisi` / `minimal 10 karakter` muncul; jumlah `orders` tidak berubah | SESUI |
| 4 | **Create** `orders/{orderId}` lewat tombol Buat Pesanan | 1 dokumen baru, `uid` = Rina, `status='menunggu'`, pindah ke Status Pesanan | `ORD-20261116-62942` tercatat dengan `uid=stjEG0…`, `status=menunggu`, `items=P01:1`, `total=55000` | SESUI |
| 5 | **Read** `orders` lewat `.where('uid').snapshots()` | Pesanan baru tampil di Riwayat Pesanan tanpa refresh manual | `ORD-20261116-62942` terbaca dari stream realtime | SESUI |
| 6 | **Aturan bisnis sebelum Create** — tolak pesanan identik yang masih `Menunggu` | Tidak ada dokumen baru, form tetap di Checkout, SnackBar penolakan tampil | `orders` tetap 3 dokumen, URL masih `#/checkout`, SnackBar merah "Pesanan dengan isi keranjang yang sama masih berstatus Menunggu…" | SESUI |
| 7 | Persistensi setelah **refresh (F5)** | Order tetap tampil; sumber data server, bukan memori | `ORD-20261116-62942` masih ada setelah halaman dimuat ulang | SESUI |
| 8 | **Realtime** — status diubah dari server | Label berubah `Menunggu → Diproses` tanpa reload | Label `Diproses` muncul ±4,5 detik setelah PATCH, tanpa refresh | SESUI |
| 9 | **Isolasi pengguna** — akun admin membuka Riwayat Pesanan | Admin tidak melihat pesanan milik Rina | Riwayat admin menampilkan `Belum ada pesanan` walaupun `orders` berisi 3 dokumen | SESUI |

**10/10 SESUI**, tanpa `console error` maupun `pageerror` di browser.

Bukti screenshot: `bukti/10-profil-kulit-tersimpan.png` … `bukti/18-isolasi-pengguna.png`.

> Catatan metodologis: skrip memilih produk yang stoknya cukup **dan** belum
> punya pesanan `menunggu` dengan tanda keranjang `<id>:1`, lalu mengosongkan
> keranjang sebagai fixture. Karena itu tabel di atas dapat diulang berkali-kali
> tanpa gagal gara-gara aturan anti-duplikat itu sendiri.

---

## 6. Lanjutan — CRUD produk admin (5 kasus)

Dijalankan dengan `node video/scripts/uji-crud-produk.js`. Setiap perubahan UI
diverifikasi ulang langsung ke server Firestore memakai token pemilik project.

| No | Kasus | Diharapkan | Hasil nyata | Status |
|---|---|---|---|---|
| 1 | Admin menambah produk lewat tombol "+ Tambah Produk" | Dokumen `products` baru, harga 77777, stok 13 | `P1795410599`, harga 77777, stok 13 | SESUI |
| 2 | Produk baru tampil di daftar Kelola Produk | Nama muncul setelah snapshot Firestore | Nama tampil di daftar | SESUI |
| 3 | Admin mengedit harga produk | Harga jadi 88888 di server | `harga = 88888` | SESUI |
| 4 | Admin menghapus produk | Dokumen hilang dari server | Tidak ditemukan | SESUI |
| 5 | Pelanggan membuka halaman Akun | Menu Dashboard Admin tidak muncul | Menu tidak muncul | SESUI |

**5/5 SESUI**, 0 console error. Dokumen uji sudah dihapus sehingga `products`
kembali berisi 10 dokumen. Bukti: `bukti/23-crud-tambah-produk.png`,
`bukti/24-crud-edit-produk.png`, `bukti/hasil-uji-crud-produk.json`.

---

## 7. Cara mengulang seluruh pengujian

```bash
# 0. Pastikan rules aktif & token firebase-tools segar
firebase firestore:databases:list --project toko-skincare-fec17
firebase deploy --only firestore:rules,firestore:indexes --project toko-skincare-fec17

# 1. Statis & unit
flutter analyze
NO_PROXY="localhost,127.0.0.1,::1" no_proxy="localhost,127.0.0.1,::1" flutter test --no-pub
flutter build web --release

# 2. Rules (langsung ke server)
python scripts/uji_rules.py

# 3. Sajikan build (terminal A)
python -m http.server 8137 --directory build/web --bind 127.0.0.1

# 4. Integrasi UI (terminal B)
cd video && NO_PROXY="127.0.0.1,localhost" node scripts/uji-firestore-m10.js   # 8/8
cd video && NO_PROXY="127.0.0.1,localhost" node scripts/uji-modul-m10.js      # 10/10
cd video && NO_PROXY="127.0.0.1,localhost" node scripts/uji-role-admin.js     # role admin
cd video && NO_PROXY="127.0.0.1,localhost" node scripts/uji-crud-produk.js    # 5/5 CRUD
cd video && NO_PROXY="127.0.0.1,localhost" node scripts/buat-bukti-data.js    # gambar isi collection

# 5. Rekam isi database
python scripts/verifikasi_data.py
```

`NO_PROXY` diperlukan karena lingkungan ini memiliki proxy yang mengganggu
akses ke `localhost` saat `flutter test`. Token `firebase-tools` dapat
kedaluwarsa; menjalankan satu perintah CLI terautentikasi akan
memperbaruinya secara otomatis.
