# Struktur Database Cloud Firestore

Lima collection sesuai rancangan pada proposal UTS. Semua dokumen ditulis oleh
`FirestoreDataSource`; konversi model ↔ `Map<String, dynamic>` ada di
`lib/data/data_sources/firestore_converters.dart` (fungsi murni, mudah diuji).

```
firestore (default) @ asia-southeast2
├── users/{uid}
├── products/{productId}
├── skin_profiles/{uid}
├── orders/{orderId}
└── carts/{uid}/items/{productId}
```

---

## 1. `users/{uid}`

ID dokumen = UID Firebase Authentication, bukan email. Ini yang membuat Rules
bisa membandingkan `request.auth.uid` secara langsung.

| Field | Tipe | Keterangan |
| --- | --- | --- |
| `uid` | string | sama dengan ID dokumen |
| `nama` | string | dari `displayName` atau bagian lokal email |
| `email` | string | dari Firebase Auth |
| `role` | string | `admin` / `pelanggan` — **sumber otorisasi** |
| `createdAt` | timestamp | `FieldValue.serverTimestamp()` saat dibuat |

Contoh:

```json
{
  "uid": "JRYpdzItPOcyCYHNI2plizDAyHg1",
  "nama": "Admin Toko",
  "email": "admin@skincare.id",
  "role": "admin",
  "createdAt": "<server timestamp>"
}
```

Dokumen dibuat otomatis oleh `_pastikanProfil()` saat login pertama. Role awal
selalu `pelanggan`; promosi hanya lewat Console / `scripts/promote_admin.py`.

---

## 2. `products/{productId}`

| Field | Tipe | Keterangan |
| --- | --- | --- |
| `id`, `nama`, `kategori` | string | identitas & filter |
| `harga`, `stok`, `paoBulan` | number | Rupiah (int), jumlah, masa PAO |
| `kandunganAktif`, `tipeKulitCocok` | array<string> | bahan & rekomendasi kulit |
| `tanggalBuka` | timestamp / null | untuk perhitungan PAO |
| `manfaat`, `caraPakai` | string | detail produk |
| `imageUrl` | string / null | opsional |
| `createdAt`, `updatedAt` | timestamp | audit |

`tanggalBuka` memakai `Timestamp.fromDate()` (bukan ISO string) supaya bisa
diurutkan di Firestore. Konverter pembaca tetap toleran terhadap string ISO
dan angka `num`, sehingga data lama tidak membuat aplikasi crash.

---

## 3. `skin_profiles/{uid}`

Satu dokumen per pengguna, ID dokumen = UID.

| Field | Tipe |
| --- | --- |
| `tipeKulit` | string |
| `concern` | array<string> |
| `alergi` | array<string> |
| `updatedAt` | timestamp |

Dipakai halaman Profil Kulit dan rekomendasi produk di Beranda.

---

## 4. `orders/{orderId}`

| Field | Tipe | Keterangan |
| --- | --- | --- |
| `uid` | string | **wajib** — dipakai Rules & query pelanggan |
| `id` | string | nomor pesanan `ORD-…` |
| `items` | array<map> | salinan `productId`, `product`, `quantity` |
| `total` | number | total Rupiah |
| `status` | string | `menunggu` → `diproses` → `dikirim` → `selesai` |
| `tanggal` | timestamp | waktu checkout |
| `alamat`, `namaPenerima`, `telepon` | string | hasil form tervalidasi |
| `createdAt`, `updatedAt` | timestamp | audit |

`items` menyimpan **salinan produk** (denormalisasi), bukan referensi, agar
riwayat pesanan tidak berubah ketika harga/nama produk diubah admin.

`updatedAt` **hanya** ditambahkan pada dokumen tingkat atas. Konverter sengaja
murni tanpa `FieldValue.serverTimestamp()` karena `FieldValue` tidak boleh
berada di dalam array/map bertingkat seperti `items[]`.

**Kenapa ada field `uid`?** Firestore memeriksa Rules pada *query*, bukan pada
setiap hasil. Query `collection('orders')` polos tidak bisa dibuktikan aman,
sehingga ditolak. Karena itu:

```dart
// Admin: seluruh pesanan
final query = _isAdmin
    ? _ordersRef
    : _ordersRef.where('uid', isEqualTo: uid);
```

---

## 5. `carts/{uid}/items/{productId}`

Sub-collection, bukan array di dalam dokumen, supaya setiap perubahan quantity
hanya menulis satu dokumen kecil.

| Field | Tipe |
| --- | --- |
| `productId` | string (sama dengan ID dokumen) |
| `product` | map (salinan data produk saat ditambahkan) |
| `quantity` | number |
| `updatedAt` | timestamp |

ID dokumen memakai `product.id`, sehingga menambah produk yang sama otomatis
menimpa dokumen lama (idempoten). `saveCart()` memakai `WriteBatch`: menulis
item yang ada dan menghapus dokumen yang tidak lagi ada di keranjang.

---

## 6. Timestamp server vs waktu lokal

| Kebutuhan | Perlakuan |
| --- | --- |
| Audit (`createdAt`, `updatedAt`) | `FieldValue.serverTimestamp()` — waktu server, konsisten lintas perangkat |
| Tanggal buka PAO | `Timestamp.fromDate(DateTime)` — waktu yang dipilih pengguna |
| Waktu pesanan | `Timestamp.fromDate(o.tanggal)` — disimpan apa adanya |

Pengurutan pesanan terbaru dilakukan di sisi klien
(`_orders.sort((a, b) => b.tanggal.compareTo(a.tanggal))`) agar tidak muncul
permintaan composite index.

---

## 7. Daftar koleksi dalam kode

```dart
const List<String> firestoreCollections = <String>[
  'users',
  'products',
  'skin_profiles',
  'orders',
  'carts',
];
```

Konstanta ini diuji oleh `test/firestore_converters_test.dart` supaya nama
collection tidak berubah tanpa sadar.
