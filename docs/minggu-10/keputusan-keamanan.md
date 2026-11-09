# Keputusan Keamanan — `firestore.rules`

Tujuan: **tidak ada `allow read, write: if true;`**, tidak ada data pengguna yang
bisa dibaca/diubah pengguna lain, dan tidak ada klien yang bisa menjadikan
dirinya admin. Berkas aturan: [`../../firestore.rules`](../../firestore.rules).

---

## 1. Prinsip yang dipakai

| Prinsip | Implementasi |
| --- | --- |
| Default deny | `match /{document=**} { allow read, write: if false; }` di akhir; semua aturan lain bersifat *whitelist* |
| Wajib autentikasi | `function isMasuk() { return request.auth != null; }` dipakai di semua cabang |
| Otorisasi berbasis dokumen | `isAdmin()` membaca `get(.../users/$(request.auth.uid)).data.role` |
| Isolasi data per pengguna | ID dokumen (`{userId}`, `{uid}`) dibandingkan dengan `request.auth.uid` |
| Role tidak bisa dinaikkan klien | Saat `create`, `request.resource.data.role == 'pelanggan'` dipaksa |
| Validasi bentuk data | `keys().hasOnly([...])`, `is int`, `is string`, `is list`, batas nilai |
| Perubahan minimal | `diff(resource.data).affectedKeys().hasOnly([...])` untuk update status & stok |
| Rules ramah query | Pelanggan wajib `where('uid', isEqualTo: uid)`; admin boleh query penuh |

---

## 2. Matriks akses

| Collection | Aksi | Pelanggan | Admin | Tanpa login |
| --- | --- | --- | --- | --- |
| `users/{uid}` | baca dokumen sendiri | ✅ | ✅ | ❌ |
| `users/{uid}` | baca dokumen orang lain | ❌ | ✅ | ❌ |
| `users/{uid}` | buat (`role=pelanggan`) | ✅ (diri sendiri) | ✅ | ❌ |
| `users/{uid}` | ubah `role` | ❌ | ✅ | ❌ |
| `users/{uid}` | hapus | ❌ | ✅ (kecuali dirinya sendiri) | ❌ |
| `products/{id}` | baca | ✅ | ✅ | ❌ |
| `products/{id}` | tambah / ubah / hapus | ❌ | ✅ | ❌ |
| `products/{id}` | **turunkan `stok` saja** | ✅ (lihat §4) | ✅ | ❌ |
| `skin_profiles/{uid}` | baca / tulis | ✅ (diri sendiri) | ✅ (diri sendiri) | ❌ |
| `skin_profiles/{uid}` | hapus | ❌ | ❌ | ❌ |
| `orders/{id}` | baca pesanan sendiri | ✅ | ✅ | ❌ |
| `orders/{id}` | baca semua pesanan | ❌ | ✅ | ❌ |
| `orders/{id}` | buat (`uid` = diri sendiri, `status=menunggu`) | ✅ | ✅ | ❌ |
| `orders/{id}` | ubah `status` | ❌ | ✅ | ❌ |
| `orders/{id}` | ubah `total` / `uid` / `items` | ❌ | ❌ | ❌ |
| `carts/{uid}/items/{id}` | baca / tulis / hapus | ✅ (diri sendiri) | ✅ (diri sendiri) | ❌ |
| collection lain | apa pun | ❌ | ❌ | ❌ |

---

## 3. Keputusan penting & alasannya

### 3.1 Admin bukan lagi email hard-code

Minggu 9 memakai `const kAdminEmail = 'admin@skincare.id'`. Siapa pun yang tahu
email itu bisa mendaftar ulang / memalsukan peran di klien. Minggu 10 memindahkan
keputusan ke server:

```rules
function isAdmin() {
  return isMasuk()
    && exists(/databases/$(database)/documents/users/$(request.auth.uid))
    && roleSaya() == 'admin';
}
```

Perubahan role di Console langsung terbaca aplikasi tanpa login ulang karena
`AuthProvider` mendengarkan `DataSync` dan menghitung ulang peran.

### 3.2 `create` users memaksa `pelanggan`

```rules
allow create: if milikSendiri(userId)
  && request.resource.data.uid == userId
  && request.resource.data.role == 'pelanggan'
  && request.resource.data.keys().hasOnly([...]);
```

Dengan demikian `POST` dokumen `users/{uid}` dari browser tidak pernah bisa
menghasilkan admin. Promosi harus lewat Firebase Console atau Admin SDK
(`scripts/promote_admin.py`) yang **melewati** Rules.

### 3.3 Query orders harus menyertakan `uid`

Rules **bukan filter**. Bila aturan baca bergantung pada `resource.data.uid`,
Firestore hanya mengizinkan query yang dapat dibuktikan aman. Karena itu
`FirestoreDataSource` memakai dua query berbeda:

```dart
final Query<Map<String, dynamic>> query = _isAdmin
    ? _ordersRef
    : _ordersRef.where('uid', isEqualTo: uid);
```

Admin diizinkan query penuh karena `isAdmin()` tidak bergantung pada dokumen
pesanan, sehingga Firestore dapat mengevaluasinya sekali untuk seluruh query.

### 3.4 Field yang boleh berubah dibatasi

Admin mengubah status pesanan lewat `updateStatus()`. Aturan:

```rules
allow update: if isAdmin()
  && request.resource.data.diff(resource.data).affectedKeys()
      .hasOnly(['status', 'updatedAt']);
```

Artinya admin pun tidak bisa mengganti `uid`, `total`, atau `items` setelah
pesanan dibuat — mencegah manipulasi riwayat transaksi.

### 3.5 Denormalisasi tidak menaruh `FieldValue` di array

`FieldValue.serverTimestamp()` hanya dipakai pada dokumen tingkat atas.
Menaruhnya di dalam `orders.items[]` akan ditolak Firestore. Karena itu
`firestore_converters.dart` sengaja murni (hanya menghasilkan `Timestamp`),
sedangkan data source yang menambahkan `createdAt` / `updatedAt`.

---

## 4. Batasan yang disadari (jujur untuk dosen)

Checkout memanggil `ProductProvider.reduceStok()` dari sisi klien. Karena paket
**Spark tidak menyediakan Cloud Functions**, satu-satunya cara menjaga stok tetap
berkurang tanpa mengubah alur UI adalah memberi izin sempit:

```rules
function hanyaKurangiStok() {
  return isMasuk()
    && request.resource.data.diff(resource.data).affectedKeys()
        .hasOnly(['stok', 'updatedAt'])
    && request.resource.data.stok is int
    && request.resource.data.stok >= 0
    && request.resource.data.stok < resource.data.stok;
}
```

Efeknya:

- ✅ Pelanggan **tidak bisa** menaikkan stok, mengubah harga, nama, atau field lain.
- ✅ Pelanggan **tidak bisa** menulis dokumen produk baru atau menghapusnya.
- ✅ Tidak ada akses anonim, tidak ada kebocoran data pengguna lain.
- ⚠️ Secara teori pengguna teknis bisa menurunkan stok tanpa membuat pesanan.

**Rencana perbaikan produksi:** pindahkan `createOrder` + `reduceStok` ke satu
`WriteBatch`/transaksi yang diverifikasi **Cloud Functions** (atau Rules dengan
`getAfter()` pada dokumen pesanan), sehingga pengurangan stok hanya sah bila ada
pesanan baru dengan `uid` yang sama. Ini membutuhkan paket Blaze dan di luar
batas tugas kuliah. Batasan ini sengaja dicatat, bukan disembunyikan.

---

## 5. Yang **tidak** dilakukan

- Tidak menyimpan password di Firestore (autentikasi sepenuhnya Firebase Auth).
- Tidak memakai `apiKey` sebagai rahasia — API key Firebase Web memang publik;
  perlindungan sesungguhnya ada di Authentication + Security Rules.
- Tidak memakai Cloud Functions, App Check, atau billing (batasan paket Spark).
- Tidak membuka akses baca `products` untuk publik: seluruh data tetap di balik
  login, sesuai brief aplikasi toko dengan akun.

---

## 6. Cara menguji aturan

```bash
# Kompilasi + deploy
firebase deploy --only firestore:rules --project toko-skincare-fec17

# Uji lewat aplikasi (lihat tabel-uji.md):
#  - login rina@mail.com  -> tidak bisa melihat pesanan admin / mengubah status
#  - login admin@skincare.id -> 10 produk ter-seed, menu admin muncul
#  - coba tulis collection asing -> PERMISSION_DENIED
```

Untuk pengujian otomatis Rules tanpa UI dapat ditambahkan
`@firebase/rules-unit-testing` + emulator Firestore pada pengembangan lanjutan.
