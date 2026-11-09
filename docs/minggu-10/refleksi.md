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

## Hasil yang bisa ditunjukkan

- `flutter analyze`: 0 error, 0 warning.
- `flutter test`: 24/24 lulus (termasuk 11 test konverter baru).
- `flutter build web --release`: berhasil.
- Uji Rules ke server: **13/13 SESUI**.
- Uji integrasi Chrome dengan Firestore nyata: **8/8 SESUI**, termasuk
  keranjang yang tetap ada setelah refresh.
- Database berisi 10 produk (auto-seed admin), 2 dokumen `users` dengan peran
  benar, dan 1 dokumen `carts/{uid}/items/P01`.

## Yang akan saya lanjutkan

- Menjalankan alur **Profil Kulit** dan **Checkout** secara otomatis agar
  `skin_profiles` dan `orders` juga terisi bukti datanya.
- Menambahkan `@firebase/rules-unit-testing` + emulator Firestore supaya Rules
  bisa diuji tanpa menyentuh database produksi.
- Mengganti kontrak repository menjadi berbasis `Stream` bila proyek
  dilanjutkan ke semester berikutnya.
