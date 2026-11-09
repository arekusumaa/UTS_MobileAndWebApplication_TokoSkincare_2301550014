# Tabel Uji Minggu 10 — Cloud Firestore

Seluruh pengujian dilakukan terhadap **database sungguhan**
`toko-skincare-fec17` (bukan emulator), dengan rules yang sudah di-deploy.

---

## 1. Verifikasi statis & unit

| No | Pemeriksaan | Perintah | Hasil |
| --- | --- | --- | --- |
| 1 | Analisis statis | `flutter analyze` | **0 error, 0 warning**, 52 info (lint lama: `prefer_const`, depresiasi `withOpacity`) |
| 2 | Unit test | `flutter test --no-pub` | **24/24 lulus** (13 validasi auth Minggu 9 + 11 konverter Firestore) |
| 3 | Build release | `flutter build web --release` | **Berhasil** (`build/web`, Wasm dry run sukses) |
| 4 | Kompilasi rules | `firebase deploy --only firestore:rules` | `rules file firestore.rules compiled successfully` |
| 5 | Deploy index | `firebase deploy --only firestore:indexes` | `deployed indexes ... successfully` |

Unit test konverter (`test/firestore_converters_test.dart`) mencakup 11 kasus:
nama 5 collection, round-trip produk, `Timestamp` PAO, toleransi tipe `num`/ISO,
role admin & fallback pelanggan, round-trip profil kulit, `productId` keranjang,
dokumen keranjang rusak, `uid`/`items`/status pesanan, status tak dikenal.

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
| `products` | 10 dokumen `P01`–`P10` | Auto-seed admin berhasil |
| `users` | 2 dokumen | `role: admin` & `role: pelanggan` |
| `carts/{pelanggan}/items` | `P01`, `quantity ≥ 1` | Keranjang benar-benar tersimpan, bukan cache lokal |
| `skin_profiles` | 0 (belum diisi pada uji ini) | Kontrak & Rules sudah diuji lewat unit test |
| `orders` | 0 (belum checkout pada uji ini) | Alur checkout sudah diuji pada video UTS |

Konfirmasi langsung contoh dokumen keranjang:

```json
{
  "productId": "P01",
  "quantity": 1,
  "product": { "nama": "Glow Cleanser Gel", "harga": 45000, "...": "..." }
}
```

---

## 5. Cara mengulang seluruh pengujian

```bash
# 0. Pastikan rules aktif
firebase deploy --only firestore:rules,firestore:indexes --project toko-skincare-fec17

# 1. Statis & unit
flutter analyze
NO_PROXY="localhost,127.0.0.1,::1" flutter test --no-pub
flutter build web --release

# 2. Rules (langsung ke server)
python scripts/uji_rules.py

# 3. Integrasi UI (terminal A)
python -m http.server 8137 --directory build/web --bind 127.0.0.1
#    Integrasi UI (terminal B)
cd video && NO_PROXY="127.0.0.1,localhost" node scripts/uji-firestore-m10.js

# 4. Rekam isi database
python scripts/verifikasi_data.py
```

`NO_PROXY` diperlukan karena lingkungan ini memiliki proxy yang mengganggu
akses ke `localhost` saat `flutter test`.
