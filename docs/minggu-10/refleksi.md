# Refleksi Minggu 10 — Dari Data Simulasi ke Cloud Firestore

**Are Kusuma Pratiwi · 23.01.55.0014 · A1**

## Apa yang berubah dari Minggu 9

Pada Minggu 9 saya merasa "aplikasi sudah terhubung Firebase", ternyata baru
bagian **autentikasi**-nya. Produk, keranjang, dan pesanan masih berada di
memori: setelah refresh, keranjang kosong lagi, dan perubahan admin tidak
pernah tersimpan. Minggu 10 memperlihatkan perbedaan antara *login ke Firebase*
dan *data tersimpan di Firebase*.

## Hal yang paling sulit

**Kontrak repository yang sinkron vs Firestore yang asinkron.** Seluruh 15
halaman dan 5 provider dibangun di Minggu 6 dengan asumsi
`List<Product> getAllProducts()` langsung mengembalikan data. Kalau saya
mengganti semua kontrak menjadi `Future`, maka hampir seluruh UI harus ditulis
ulang menjelang UTS — risikonya jauh lebih besar daripada manfaatnya.

Solusi yang saya pilih: **cache lokal + listener `snapshots()` + optimistic
write**. Pembacaan tetap sinkron dari cache, penulisan langsung mengubah cache
lalu mengirim ke Firestore secara async, dan `DataSync` membangunkan semua
Provider ketika ada perubahan dari server. Hasilnya UI tidak berubah sama
sekali, tetapi data jadi persisten dan realtime. Saya menyadari ini adalah
*compromise* arsitektur: untuk aplikasi produksi, kontrak berbasis `Stream`
akan lebih jujur. Untuk lingkup kuliah, pendekatan ini menjaga fitur Minggu
6/7/9 tetap utuh.

## Hal yang tidak saya duga sebelumnya

1. **Cloud Firestore API tidak otomatis aktif.** Firebase Console sudah bisa
   dipakai untuk Authentication, tetapi `firestore:databases:list` tetap 403
   karena *Service Usage API* project belum mengaktifkan
   `firestore.googleapis.com`. Awalnya saya mengira ini bug kode. Setelah
   diaktifkan lewat Service Usage REST API memakai token `firebase-tools`,
   database `(default)` baru bisa dibuat. Pelajaran: error 403 di level project
   sering bukan masalah aplikasi.
2. **Rules bukan filter.** Query `collection('orders')` polos ditolak walaupun
   setiap dokumen memang milik pengguna, karena Firestore tidak mau mengambil
   risiko mengevaluasi Rules satu per satu. Karena itu customer **wajib**
   memakai `where('uid', isEqualTo: uid)`. Ini membuat saya menambah field
   `uid` secara eksplisit di desain dokumen pesanan.
3. **Tabrakan nama `Order`.** `cloud_firestore_platform_interface` ikut
   mengekspor kelas bernama `Order`. Solusinya `import ... hide Order`, dan saya
   menemukan ini lewat `flutter analyze`, bukan saat menulis kode.
4. **`FieldValue.serverTimestamp()` tidak boleh ada di dalam array.** Awalnya
   konverter menaruh timestamp di setiap `items[]` pesanan. Saya memisahkan
   konverter menjadi fungsi murni, dan timestamp server hanya ditambahkan pada
   dokumen tingkat atas.
5. **Listener pesanan sempat tidak terpasang.** Karena kode awal hanya memasang
   ulang listener saat nilai `_isAdmin` berubah, padahal nilai awalnya `false`
   untuk pelanggan maupun admin. Ini ketahuan saat menelusuri mengapa Riwayat
   Pesanan kosong.

## Tentang keamanan

Bagian yang paling saya perhatikan: **klien tidak boleh bisa mengangkat dirinya
menjadi admin**. Sebelumnya peran ditentukan dari email hard-code di Dart —
siapa pun yang membaca kode bisa mengetahui jalannya. Sekarang peran dibaca dari
`users/{uid}` dan Rules memaksa `role == 'pelanggan'` saat dokumen dibuat.
Saya juga menulis skrip `uji_rules.py` yang menembak langsung REST API memakai
ID token pelanggan, supaya yang diuji benar-benar keputusan server, bukan
sekadar tombol yang disembunyikan.

Saya tetap mencatat satu **batasan yang disadari**: pelanggan masih diizinkan
menurunkan stok (hanya field `stok`, hanya nilai yang lebih kecil). Ini
diperlukan agar checkout lama tetap berjalan tanpa Cloud Functions, yang tidak
tersedia di paket Spark. Untuk produksi, pengurangan stok harus dipindah ke
transaksi/Cloud Functions yang memverifikasi pesanan. Menuliskan batasan ini
lebih jujur daripada mengklaim sistem "sudah sempurna aman".

## Yang berubah setelah membaca modul resmi

Implementasi Minggu 10 yang pertama sudah benar secara fungsi, tetapi masih
**belum mengikuti bentuk yang diminta modul**: halaman membaca data lewat
Provider/cache, bukan `StreamBuilder` + `.snapshots()`, dan tidak ada lapisan
`lib/services/layanan_firestore.dart`. Setelah membaca DOCX/PPTX saya menambah:

- `LayananToko` (kontrak) dengan dua implementasi: `LayananFirestore` untuk
  produksi dan `LayananMemori` untuk widget test tanpa Firebase.
- `StreamBuilder` langsung pada Daftar Produk, Riwayat Pesanan, dan sapaan
  Beranda; tiga keadaan stream (waiting / error / kosong) dipusatkan di
  `StreamKeadaan<T>`.
- **Aturan bisnis sebelum Create** (`cekAturanPesanan()`) sebagai padanan
  "cegah jadwal bentrok" RoomBook.
- 12 widget test + 14 unit test layanan, sehingga total jadi 50 test.

Pelajaran arsitekturnya: *cache + listener* yang saya bangun sebelumnya cukup
untuk migrasi data, tetapi **tidak cukup untuk membuktikan realtime** di hadapan
modul. Dua lapisan itu akhirnya saya biarkan hidup berdampingan dengan peran
yang jelas, dan saya tuliskan alasannya di [`modul-resmi.md`](modul-resmi.md).

---

## Jawaban pertanyaan refleksi modul

### 1. Field apa yang saya denormalisasi di collection utama, dan mengapa?

Field **`items[]` pada dokumen `orders/{orderId}`**. Setiap elemen menyimpan
salinan data produk hasil `cartItemToFirestore()`: `productId`, `nama`, `harga`,
`kategori`, `kandunganAktif`, `tipeKulitCocok`, dan `quantity` — bukan hanya ID
referensi ke `products/{id}`.

Alasannya: pesanan adalah **fakta historis**. Kalau Riwayat Pesanan hanya
menyimpan `productId`, maka saat admin mengubah harga atau menghapus produk,
riwayat pelanggan ikut berubah (atau malah gagal ditampilkan). Dengan salinan
data saat transaksi, halaman Riwayat cukup membaca **satu dokumen** per pesanan
tanpa *join* ke `products`, lebih cepat, dan tetap benar secara audit. Konsekuensi
yang saya sadari: data produk di riwayat bisa basi bila ada perubahan nama/harga,
tetapi untuk riwayat transaksi justru itulah yang diinginkan. Field yang memang
harus selalu *live* (stok, harga jual saat ini) tetap saya baca dari `products`.

### 2. Kendala Firestore apa yang saya temui, dan bagaimana saya mengatasinya?

Ada tiga, dua di antaranya baru muncul saat mengerjakan modul resmi:

1. **Cloud Firestore API belum aktif di level project** — `403 Cloud Firestore
   API has not been used in project ... before or it is disabled`, padahal
   Authentication sudah jalan. Diaktifkan lewat **Service Usage REST API**
   (`services/firestore.googleapis.com:enable`) memakai token `firebase-tools`,
   lalu database `(default)` dibuat di `asia-southeast2`.
2. **Composite index / `failed-precondition`** — menggabungkan
   `.where('uid', ...)` dengan `.orderBy('tanggal')` atau beberapa filter
   kategori memicu permintaan index. Solusinya sesuai petunjuk slide 14–15:
   **satu `.where()` saja**, lalu `List.sort()` dan `terapkanFilterProduk()`
   di sisi Dart dari snapshot terbaru. `firestore.indexes.json` sengaja kosong.
3. **Rules bukan filter** — query `collection('orders')` polos ditolak server
   walaupun semua dokumennya milik pengguna itu. Solusinya field `uid`
   eksplisit + `.where('uid', isEqualTo: uid)`, yang sekaligus memberi bukti
   isolasi data (kasus uji #9).

Kendala kecil lain: `cloud_firestore_platform_interface` ikut mengekspor kelas
`Order`, sehingga semua import terkait harus memakai `hide Order`; dan
`FieldValue.serverTimestamp()` tidak boleh ditaruh di dalam array `items[]`,
jadi konverter saya jadikan fungsi murni.

### 3. Fitur Edit/Delete apa yang saya rencanakan untuk Minggu 11?

Modul Minggu 10 membatasi diri pada **Create & Read**, jadi belum ada tombol
Ubah/Hapus untuk data transaksi. Rencana Minggu 11:

| Fitur | Collection | Perubahan kode & Rules yang dibutuhkan |
| --- | --- | --- |
| Ubah jumlah / hapus item keranjang | `carts/{uid}/items` | Sudah ada di UI (`CartItemTile`); tinggal dibuktikan lagi dengan uji Create/Update/Delete dan screenshot |
| Ubah status pesanan | `orders/{id}` | Admin: `updateStatus()` + Rules `allow update` yang **hanya** mengizinkan `status` & `updatedAt` berubah (sudah disiapkan di `firestore.rules`, belum ada tombolnya) |
| Batalkan pesanan | `orders/{id}` | Pelanggan boleh membatalkan hanya saat `status == 'menunggu'`, dengan `request.resource.data.diff(...).affectedKeys().hasOnly(['status','updatedAt'])` dan kembalikan stok lewat transaksi |
| Edit / hapus produk | `products/{id}` | Admin: `FormProdukScreen` sudah ada; Rules `allow update/delete: if isAdmin()` sudah aktif, tinggal uji Update/Delete |
| Edit profil kulit | `skin_profiles/{uid}` | Rules `allow create, update` sudah ada; UI tinggal menambah mode ubah |

Yang harus saya perhatikan: **Update/Delete tidak boleh membuka celah
eskalasi peran**. Karena itu `uid`, `role`, `total`, dan `items` tetap dikunci
pada `affectedKeys()`, dan pengurangan/pengembalian stok sebaiknya dipindah ke
transaksi atau Cloud Functions bila nanti tersedia billing.

---

## Hasil yang bisa ditunjukkan

- `flutter analyze`: **0 error, 0 warning** (50 info lint lama).
- `flutter test`: **50/50 lulus** (13 auth + 11 konverter + 14 layanan + 12 widget).
- `flutter build web --release`: berhasil.
- Uji Rules ke server: **13/13 SESUI**.
- Uji integrasi migrasi Chrome: **8/8 SESUI**.
- **Uji resmi modul Create & Read: 10/10 SESUI**, tanpa console error —
  mencakup Create `skin_profiles` & `orders`, Read realtime, aturan bisnis
  penolakan duplikat, persistensi F5, perubahan status realtime, isolasi pengguna.
- Database berisi 10 `products`, 2 `users` dengan peran benar, 1
  `skin_profiles`, 3 `orders`, dan 1 `carts/{uid}/items/P01`.

## Yang akan saya lanjutkan

- Mengambil **2 screenshot Firebase Console** (Data + Rules) secara manual,
  karena memerlukan sesi login Google; `19-isi-collection.png` hanyalah
  ringkasan dari REST API dan sudah diberi catatan kejujuran.
- Menambahkan `@firebase/rules-unit-testing` + emulator Firestore supaya Rules
  bisa diuji tanpa menyentuh database produksi.
- Mengganti kontrak repository menjadi berbasis `Stream` bila proyek
  dilanjutkan ke semester berikutnya, agar tidak ada lagi duplikasi lapisan
  `AppRepositories` dan `LayananToko`.
