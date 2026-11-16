# Pemetaan Modul Resmi Minggu 10 — Cloud Firestore: Collection, Tambah & Tampilkan Data

**Are Kusuma Pratiwi · 23.01.55.0014 · A1 / A2DLC**
**Mata kuliah:** Pengembangan Aplikasi Mobile dan Web — Ganjil 2026/2027
**Aplikasi:** SkinCare Store · **Branch:** `minggu-10-firestore`

---

## 1. Sumber acuan

| Sumber | Isi yang dipakai |
| --- | --- |
| `modul-minggu-10-firestore.docx` | Latihan 1–4, tabel uji ≥5 kasus, 3 pertanyaan refleksi, daftar luaran |
| `materi-ajar-minggu-10-firestore.pptx` | Slide 9 `LayananFirestore` / `LayananMemori`; slide 10–12 `users`, `rooms`, `reservations`; slide 14–15 `StreamBuilder` + tiga keadaan; slide 17 tabel uji; slide 19 Create/Read saja |
| Video panduan `https://youtu.be/ibqVFb5ytyY` | Judul *"Mobile and Web Defelopment - firestore"*, kanal `nayantaka`, durasi ±3:32. Transkrip tidak dapat diambil, sehingga **DOCX/PPTX dijadikan acuan utama** |

Modul memakai studi kasus **RoomBook** (`users`, `rooms`, `reservations`).
Padanannya di SkinCare Store:

| RoomBook (modul) | SkinCare Store | Keterangan |
| --- | --- | --- |
| `users` (profil) | `users` | Sapaan realtime di Beranda, peran admin |
| `rooms` (master data) | `products` | 10 produk, dibaca `.snapshots()` |
| `reservations` (transaksi) | `orders` | Create saat checkout, Read di Riwayat Pesanan |
| Cegah **jadwal bentrok** | Cegah **stok kurang** & **pesanan identik masih Menunggu** | Aturan bisnis sebelum Create |
| — | `skin_profiles`, `carts` | 2 collection tambahan sesuai proposal UTS |

Modul meminta **minimal 3 collection**; project ini punya **5 collection**
karena proposal UTS sudah menetapkannya sejak Minggu 8.

---

## 2. Pemetaan butir modul → implementasi

| Butir modul | Status | Bukti di project |
| --- | --- | --- |
| Paket **Spark**, target **Chrome**, tanpa Cloud Functions | ✅ | `firebase.json`, `flutter build web --release` |
| Hanya operasi **Create & Read** (Update/Delete Minggu 11) | ✅ | `LayananToko` hanya `stream*` + `tambahPesanan`; admin mengubah status lewat Console/Admin SDK, bukan tombol aplikasi baru |
| Tiga collection tersedia & berisi data | ✅ | `users` 2, `products` 10, `orders` 3, `skin_profiles` 1, `carts/{uid}/items` 1 — [`isi-firestore.json`](isi-firestore.json), [`bukti/19-isi-collection.png`](bukti/19-isi-collection.png) |
| Abstraksi `lib/services/layanan_firestore.dart` | ✅ | [`lib/services/layanan_firestore.dart`](../../lib/services/layanan_firestore.dart): `LayananToko` (kontrak), `LayananFirestore`, `LayananMemori` |
| UI **tidak** memanggil `FirebaseFirestore.instance` langsung | ✅ | Semua akses lewat `context.read<LayananToko>()` atau parameter `layanan` |
| `StreamBuilder` + `.snapshots()` | ✅ | `DaftarProdukScreen`, `RiwayatPesananScreen`, `BerandaScreen`, `StreamKeadaan<T>` |
| Tiga keadaan: `waiting` / `hasError` / data kosong | ✅ | `StreamKeadaan<T>` + 4 widget test khusus |
| Real-time: data berubah tanpa refresh | ✅ | Kasus uji #8 (status `Menunggu → Diproses` dari server) |
| Persistensi setelah refresh | ✅ | Kasus uji #7 |
| Isolasi data per pengguna | ✅ | `.where('uid', isEqualTo: uid)`, Rules query wajib filter `uid`, kasus uji #9 |
| **Aturan bisnis sebelum Create** | ✅ | `cekAturanPesanan()` — cek stok dari server + tolak pesanan identik `menunggu` |
| Satu `.where()` saja, sort/filter di Dart | ✅ | `terapkanFilterProduk()`, `List.sort()` — menghindari `failed-precondition / requires an index` |
| Tabel uji ≥5 kasus (harapan vs hasil nyata) | ✅ | [Bagian 5 `tabel-uji.md`](tabel-uji.md) — **10 kasus**, semua SESUI |
| Refleksi 3 pertanyaan modul | ✅ | [Bagian "Jawaban pertanyaan refleksi modul" `refleksi.md`](refleksi.md) |
| Screenshot collection | ⚠️ | 16 screenshot aplikasi + 1 gambar isi collection dari REST API. **2 screenshot Console asli masih manual** (butuh login Google) |
| ≥2 commit baru | ✅ | Lihat `git log` pada branch `minggu-10-firestore` |
| Security Rules aman | ✅ | Modul memberi contoh `allow read, write: if request.auth != null`; project memakai aturan **lebih ketat** (default-deny + peran + kepemilikan), lihat [`keputusan-keamanan.md`](keputusan-keamanan.md) |

> **Catatan desain:** modul memberi contoh Rules sederhana
> `allow read, write: if request.auth != null`. Saya tidak memakainya apa adanya
> karena aturan itu mengizinkan pelanggan mengubah harga produk, menghapus
> pesanan orang lain, atau mengangkat dirinya jadi admin. Rules final tetap
> memenuhi semangat modul (wajib login), tetapi membatasi tiap collection.

---

## 3. Arsitektur lapisan layanan

```
┌──────────────────────── UI (StreamBuilder / StreamKeadaan) ──────────────────┐
│  BerandaScreen   DaftarProdukScreen   RiwayatPesananScreen   CheckoutScreen │
└───────────────────────────┬─────────────────────────────────────────────────┘
                            │ context.read<LayananToko>() / parameter `layanan`
                            ▼
                 abstract class LayananToko
   ┌─────────────────────────────┴──────────────────────────────┐
   ▼                                                            ▼
LayananFirestore (produksi)                          LayananMemori (widget test)
 • products.snapshots()                             • data di memori, tanpa Firebase
 • orders.where('uid').snapshots()                  • `tunda` → uji waiting
 • users/{uid}.snapshots()                          • `simulasiError` → uji hasError
 • cekAturanPesanan()                              • `tambahPesanan` → uji realtime
 • tambahPesanan() → orders/{id}
```

Injeksi dilakukan di `lib/main.dart`:

```dart
final LayananToko layanan =
    pakaiMock ? LayananMemori() : LayananFirestore();
runApp(SkinCareStoreApp(repos: repos, layanan: layanan));
// ...
Provider<LayananToko>.value(value: layanan),
```

Dua lapisan data memang sengaja hidup berdampingan:

* `AppRepositories` + `FirestoreDataSource` — **lapisan lama** (Minggu 10 awal),
  mempertahankan kontrak repository sinkron untuk 5 Provider agar 15 halaman
  tidak perlu ditulis ulang. Menangani auto-seed, `users/{uid}` saat login
  pertama, dan keranjang.
* `LayananToko` — **lapisan modul resmi**, dipakai halaman yang memang harus
  menampilkan data realtime lewat `StreamBuilder` dan menulis dokumen `orders`.

---

## 4. Create & Read yang benar-benar berjalan

### Read — `StreamBuilder` + `.snapshots()`

```dart
// Daftar Produk: master data (padanan `rooms`)
StreamBuilder<List<Product>>(
  stream: layanan.streamDaftarProduk(),   // products.snapshots()
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData)
      return const Center(child: CircularProgressIndicator());
    if (snapshot.hasError) return const EmptyState(/* pesan ramah */);
    final products = terapkanFilterProduk(snapshot.data ?? const [], ...);
    ...
  },
)
```

```dart
// Riwayat Pesanan: transaksi milik sendiri (padanan Reservasi Saya)
_db.collection('orders')
   .where('uid', isEqualTo: uid)     // SATU where → aman bagi Rules
   .snapshots()
   .map((qs) => qs.docs.map(orderFromFirestore).toList()
     ..sort((a, b) => b.tanggal.compareTo(a.tanggal)));  // sort di Dart
```

### Create — validasi → aturan bisnis → dokumen

```dart
// CheckoutScreen._handleCheckout()
if (!(_formKey.currentState?.validate() ?? false)) return;     // 1. validasi form
final penolakan = await layanan.cekAturanPesanan(cart.items);   // 2. aturan bisnis
if (penolakan != null) { /* SnackBar, form tetap terbuka */ return; }
final order = orderProvider.buatOrder(...);
await layanan.tambahPesanan(order);                            // 3. Create orders/{id}
```

`cekAturanPesanan()` adalah padanan **"cegah jadwal bentrok"** RoomBook:

1. **Stok** dibaca dari server (`products/{id}.get()`), bukan dari cache klien.
   Bila `stok < quantity`, pesanan ditolak.
2. **Pesanan identik** yang masih berstatus `menunggu` ditolak. Tanda keranjang
   dihitung deterministik sebagai pasangan `productId:quantity` yang diurutkan
   (`tandaKeranjang()`), sehingga urutan isi keranjang tidak memengaruhi hasil.

Bila ditolak, **tidak ada dokumen baru** dan form Checkout tetap terbuka
(terbukti pada kasus uji #6).

### Denormalisasi yang disengaja

`orders/{id}.items[]` menyimpan salinan data produk (`cartItemToFirestore`):
`productId`, `nama`, `harga`, `kandunganAktif`, dll. Dengan begitu Riwayat
Pesanan tetap menampilkan **harga dan nama produk pada saat transaksi**, walaupun
data di `products` kelak diubah atau dihapus admin — tanpa perlu *join* ke
`products` untuk setiap baris.

---

## 5. Tiga keadaan `StreamBuilder`

| Keadaan | Penanganan | Widget test |
| --- | --- | --- |
| `ConnectionState.waiting` & belum ada data | `CircularProgressIndicator` | `waiting menampilkan CircularProgressIndicator`, `waiting menampilkan loading` |
| `snapshot.hasError` | `EmptyState` "Data belum bisa dimuat" + pesan cek koneksi/Rules | `error menampilkan pesan ramah`, `error stream menampilkan EmptyState` |
| Data kosong | `EmptyState` "Belum ada pesanan" / "Produk tidak ditemukan" | `data kosong menampilkan EmptyState`, `belum ada pesanan → EmptyState` |
| Data tersedia | `builder(...)` | `data tersedia diteruskan ke builder`, `dokumen baru muncul tanpa refresh` |

Helper bersama: [`lib/widgets/common/stream_keadaan.dart`](../../lib/widgets/common/stream_keadaan.dart).

---

## 6. Bukti & cara mengulang

```bash
# Build + sajikan
flutter build web --release
python -m http.server 8137 --directory build/web --bind 127.0.0.1

# Terminal lain
firebase firestore:databases:list --project toko-skincare-fec17  # segarkan token CLI
python scripts/uji_rules.py                 # 13/13 SESUI
cd video && NO_PROXY="127.0.0.1,localhost" node scripts/uji-modul-m10.js   # 10/10 SESUI
cd video && NO_PROXY="127.0.0.1,localhost" node scripts/buat-bukti-data.js
python scripts/verifikasi_data.py

# Unit & widget test
NO_PROXY="localhost,127.0.0.1,::1" flutter test --no-pub    # 50/50
flutter analyze                                             # 0 error, 0 warning
```

| Berkas bukti | Isi |
| --- | --- |
| [`bukti/hasil-uji-modul.json`](bukti/hasil-uji-modul.json) | 10 kasus resmi, harapan vs hasil nyata |
| [`bukti/10-…18-*.png`](bukti/) | 9 screenshot alur Create/Read di aplikasi |
| [`bukti/19-isi-collection.png`](bukti/19-isi-collection.png) | Isi 5 collection + tabel `orders` / `skin_profiles` dari REST API |
| [`bukti/tree-tolak-duplikat.txt`](bukti/tree-tolak-duplikat.txt) | Accessibility tree berisi pesan penolakan duplikat |
| [`hasil-uji-rules.json`](hasil-uji-rules.json) | 13 keputusan server terhadap Rules |
| [`isi-firestore.json`](isi-firestore.json) | Rekaman isi database |

### Yang masih manual

- [ ] Screenshot **Firebase Console → Firestore Data** →
      `docs/minggu-10/bukti/20-firestore-console-data.png`
- [ ] Screenshot **Firebase Console → Firestore Rules** →
      `docs/minggu-10/bukti/21-firestore-console-rules.png`

Keduanya memerlukan sesi login Google mahasiswa. Gambar
`19-isi-collection.png` **bukan** screenshot Console dan sudah diberi catatan
kejujuran di dalamnya; jangan mengklaimnya sebagai screenshot Console.
