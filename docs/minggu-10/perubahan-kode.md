# Perubahan Kode: `MockDataSource` → `FirestoreDataSource`

## 1. Masalah arsitektur

Kontrak repository warisan Minggu 6 bersifat **sinkron**:

```dart
abstract class ProductRepository {
  List<Product> getAllProducts();
  void addProduct(Product product);
}
```

Cloud Firestore bersifat **asinkron dan berbasis stream**. kalau kontrak diubah
menjadi `Future<List<Product>>`, maka 15 halaman UI, 5 provider, dan seluruh
`context.watch` harus ditulis ulang — risiko regresi besar menjelang UTS.

## 2. Solusi: cache lokal + snapshot realtime + optimistic write

```
                    ┌──────────── Firestore ────────────┐
                    │  snapshots() → perubahan realtime │
                    └───────────────┬───────────────────┘
                                    │
   UI ──sync read──▶ Provider ──▶ FirestoreDataSource
                          ▲              │
                          │              ├─ cache: List/Map lokal
                          │              ├─ write: async (fire-and-forget)
                          │              └─ optimistic update cache dulu
                          │
                    DataSync.berubah() ──▶ notifyListeners()
```

- **Baca**: `getAllProducts()` mengembalikan salinan cache secara sinkron.
- **Tulis**: cache langsung diubah (`optimistic`), lalu `_kirim()` menjalankan
  operasi Firestore secara async dan menangkap `FirebaseException`.
- **Realtime**: listener `snapshots()` memperbarui cache dan memanggil
  `onChanged`. `DataSync` (ChangeNotifier) membangunkan semua Provider.
- UI tetap responsif walau jaringan lambat; data dari perangkat lain masuk
  tanpa refresh halaman.

## 3. Suntikan dependensi

`lib/data/app_repositories.dart` menyatukan kelima repository:

```dart
factory AppRepositories.firestore() {
  final sync = DataSync();
  final source = FirestoreDataSource(onChanged: sync.berubah);
  return AppRepositories._(
    products: source, orders: source, skinProfiles: source,
    users: source, carts: source, sync: sync, firestore: source,
  );
}
```

Satu objek `FirestoreDataSource` mengimplementasikan kelima kontrak sekaligus,
sehingga berbagi cache dan listener yang sama. `main.dart` memilih mode:

```dart
const bool pakaiMock = bool.fromEnvironment('PAKAI_MOCK');
final repos = pakaiMock ? AppRepositories.mock() : AppRepositories.firestore();
repos.initialize();   // sengaja tidak di-await agar startup tidak macet
runApp(SkinCareStoreApp(repos: repos));
```

`MultiProvider` kemudian menyuntikkan `source:` dan `sync:` ke setiap Provider.
Semua parameter konstruktor **opsional**, sehingga `ProductProvider()` lama
tetap bekerja pada widget test.

## 4. Daftar berkas

### Berkas baru

| Berkas | Peran |
| --- | --- |
| `lib/data/data_sources/firestore_data_source.dart` | Implementasi kelima repository + cache + listener + seed |
| `lib/data/data_sources/firestore_converters.dart` | Konversi model ↔ dokumen (fungsi murni, tanpa `FieldValue`) |
| `lib/data/data_sources/mock_cart_source.dart` | Keranjang in-memory untuk test / mode mock |
| `lib/data/repositories/cart_repository.dart` | Kontrak baru `getCart()` / `saveCart()` |
| `lib/data/data_sync.dart` | `ChangeNotifier` jembatan snapshot → Provider |
| `lib/data/app_repositories.dart` | Dependency injection: `firestore()` / `mock()` / `custom()` |
| `firestore.rules` | Aturan keamanan |
| `firestore.indexes.json` | Daftar index (kosong, sengaja) |
| `scripts/promote_admin.py` | Promosi admin lewat REST API pemilik project |
| `test/firestore_converters_test.dart` | 11 unit test konversi |
| `docs/minggu-10/*` | Dokumentasi modul |

### Berkas diubah

| Berkas | Perubahan |
| --- | --- |
| `lib/data/repositories/user_repository.dart` | Kontrak lama (`login`, `register`, password) diganti `getUserById`, `isAdmin`, `ensureProfile` |
| `lib/data/data_sources/mock_user_source.dart` | Disesuaikan dengan kontrak baru, tidak menyimpan password |
| `lib/main.dart` | Membuat `AppRepositories`, menyuntikkan ke 5 Provider, flag `PAKAI_MOCK` |
| `lib/providers/product_provider.dart` | Menerima `ProductRepository` + `Listenable`, refresh cache saat snapshot |
| `lib/providers/order_provider.dart` | Menerima `OrderRepository` + `Listenable`; ID pesanan dibuat unik memakai `millisecondsSinceEpoch` |
| `lib/providers/cart_provider.dart` | Menerima `CartRepository`; **setiap** mutasi kini memanggil `saveCart()` |
| `lib/providers/skin_profile_provider.dart` | Menerima `SkinProfileRepository` + `Listenable`, menyimpan UID terakhir untuk reload |
| `lib/providers/auth_provider.dart` | Role dibaca dari `UserRepository`; `kAdminEmail` hanya fallback mode mock |
| `firebase.json` | Tambah referensi `firestore.rules` & `firestore.indexes.json` |
| `pubspec.yaml` / `pubspec.lock` | Tambah `cloud_firestore: ^7.1.0` |
| `lib/screens/auth/masuk_daftar_page.dart` | Hapus `import go_router` yang tidak terpakai |

**Tidak ada halaman UI yang diubah** — ini poin penting: seluruh 15 screen
Minggu 6/7 dan 9 tetap utuh.

## 5. Detail `FirestoreDataSource`

| Bagian | Isi |
| --- | --- |
| Cache | `_products`, `_orders`, `_cart`, `_profiles`, `_users`, `_orderOwner`, `_cartDocIds` |
| Auth | `initialize()` mendengarkan `authStateChanges()`; `_epoch` membatalkan proses lama saat login berubah cepat |
| Profil | `_pastikanProfil()` membuat `users/{uid}` dengan `role: pelanggan` |
| Listener | `users/{uid}`, `products`, `skin_profiles/{uid}`, `carts/{uid}/items`, `orders` |
| Orders | Query berbeda admin vs pelanggan; listener dipasang ulang saat peran berubah |
| Seed | `_cobaSeedOtomatis()` → `seedProductsIfEmpty()` (batch 10 produk, sekali per sesi) |
| Error | `_setError()` menyimpan pesan terakhir (`lastError`) tanpa melempar exception ke UI |
| Logout | Semua listener dihentikan dan cache dikosongkan, mencegah kebocoran data antar-akun |

### Perbaikan yang ditemukan saat implementasi

1. **Listener pesanan tidak pernah terpasang untuk pelanggan** — awalnya hanya
   dipanggil saat `_isAdmin` berubah, padahal nilai awalnya `false` untuk dua
   peran. Sekarang `_pasangUlangOrdersListener()` dipanggil eksplisit di
   `_onAuthChanged()`.
2. **`initialize()` memblokir startup** — versi awal `await` jaringan. Sekarang
   `void` + `unawaited(...)`; aplikasi tetap tampil walau Firestore mati.
3. **Tabrakan nama `Order`** — `cloud_firestore_platform_interface` mengekspor
   kelas `Order`. Semua import `cloud_firestore` diberi `hide Order`.
4. **ID pesanan bisa duplikat** — `orders.length + 1` menimpa dokumen saat dua
   checkout berurutan; diganti suffiks `millisecondsSinceEpoch`.
5. **`FieldValue` di dalam array** — konverter dipisah agar murni; timestamp
   server hanya ditambahkan pada dokumen tingkat atas.

## 6. Mode simulasi tetap ada

```bash
flutter run -d chrome --dart-define=PAKAI_MOCK=true
```

Ini memakai `AppRepositories.mock()` (5 `Mock*Source`) tanpa menyentuh Firestore,
berguna untuk screenshot UTS, demo offline, dan widget test. Brief UTS masih
mengizinkan data simulasi, jadi kedua mode dapat ditunjukkan ke penguji.

## 7. Perbaikan peran admin (login `admin@skincare.id`)

Dokumen `users/JRYpdzItPOcyCYHNI2plizDAyHg1` di Firestore sudah benar
(`role: admin`). Dua kondisi membuat UI tetap menampilkan **Pelanggan**:

1. **Mode simulasi** — `MockData.users` memakai ID statis `U01`, sedangkan
   Firebase Auth memberi UID `JRYpdzItPOcyCYHNI2plizDAyHg1`. Lookup
   `isAdmin(uid)` selalu gagal.
2. **Frame pertama login** — cache `users` belum terisi saat
   `AuthProvider.login()` menghitung peran, sebelum snapshot Firestore datang.

Perbaikannya:

- `lib/core/utils/validasi_auth.dart` → `tentukanRole(email, roleDariProfil)`.
  Profil Firestore tetap menjadi sumber kebenaran; fallback email hanya dipakai
  bila profil belum ada.
- `lib/providers/auth_provider.dart` → memakai helper tersebut, jadi peran admin
  langsung benar walau snapshot belum selesai.
- `lib/data/data_sources/mock_user_source.dart` → selain by UID, lookup juga
  mencocokkan email lewat closure `emailSaatIni` yang disuntikkan
  `AppRepositories.mock()`. Widget test tanpa Firebase tetap aman karena
  closure bersifat opsional dan dipanggil malas.

Bukti: `docs/minggu-10/bukti/22-role-admin-tampil.png` (badge **Admin** dan menu
**Dashboard Admin — Kelola produk & pesanan** muncul). Uji otomatis:
`test/validasi_auth_test.dart` grup `tentukanRole` (5 kasus) dan
`test/mock_user_source_test.dart` (5 kasus). Total `flutter test` **59/59**.

## 8. Lanjutan — CRUD produk admin (Update/Delete)

Modul Minggu 10 hanya mewajibkan Create & Read; Update/Delete sudah ada di
kode sejak awal lewat `ProductRepository` dan benar-benar menulis ke
Firestore. Yang kurang adalah **keterlihatan**: tombol tambah hanya berupa
FAB `+`, dan ikon edit/hapus tanpa keterangan.

Tampilan `lib/screens/admin/kelola_produk_screen.dart` sudah diperbarui:

- Panel header **Katalog Produk** memakai latar gradien pink, tiga kartu
  statistik (**Produk**, **Stok menipis**, **Stok habis**), dan tombol besar
  **"+ Tambah Produk Baru"** (di mobile: **"+ Tambah"**).
- Kolom pencarian nama/kategori/kandungan, `ChoiceChip` filter kategori,
  dropdown urutan (nama A–Z/Z–A, harga, stok), keterangan
  "Menampilkan X dari Y produk", serta tombol **Reset filter**.
- Setiap baris memakai avatar berwarna sesuai kategori, badge status stok
  (**Aman** / **Menipis** / **Habis**), dan tombol bertulisan **Edit** /
  **Hapus** dengan `Tooltip` nama produk.
- Baris tetap bisa diklik untuk edit; hapus lewat dialog konfirmasi.
- Empty state dibedakan antara "Belum ada produk" dan "Produk tidak ditemukan".
- AppBar punya tombol **Refresh** (`ProductProvider.refreshData()`) dan
  **Tambah**; form produk diberi tombol **Batal**.

Semua kontrol di atas benar-benar berfungsi. Filter dan pengurutan dilakukan
di sisi Dart dari snapshot Firestore, jadi tidak butuh composite index baru.

Operasi tulis sudah memakai jalur yang aman:

| Aksi | Kode | Dokumen Firestore |
|---|---|---|
| Tambah | `ProductProvider.addProduct()` → `FirestoreDataSource.addProduct()` | `products/{id}` — `set()` + `createdAt` |
| Edit | `ProductProvider.updateProduct()` | `set(SetOptions(merge: true))` + `updatedAt` |
| Hapus | `ProductProvider.deleteProduct()` | `products/{id}.delete()` |

Security Rules `match /products/{productId}` mengizinkan create/update/delete
**hanya untuk admin**; pelanggan hanya boleh membaca dan menurunkan `stok`.

Uji integrasi `video/scripts/uji-crud-produk.js` (login admin → tambah → cek
server → edit → cek server → hapus → cek server → logout → login pelanggan →
cek menu admin): **5/5 SESUI**, 0 console error. Bukti:
`bukti/23-crud-tambah-produk.png`, `bukti/24-crud-edit-produk.png`,
`bukti/hasil-uji-crud-produk.json`. Dokumen uji otomatis sudah dihapus dari
database (jumlah `products` kembali ke 10).

## 9. Penyegaran tampilan menyeluruh

Permintaan berikutnya adalah mengubah tampilan **seluruh** website, bukan hanya
halaman admin. Perubahan dilakukan di lapisan tema agar konsisten ke 18 layar:

| Berkas | Perubahan |
|---|---|
| `lib/core/theme/app_colors.dart` | Permukaan hangat `#FFF9FB`, `primaryGlow`, pasangan gradien pink, warna kategori yang lebih jenuh. Identitas `#D95778` tetap dipertahankan. |
| `lib/core/theme/app_theme.dart` | AppBar melengkung 20px + bayangan pink, kartu radius 18px + elevasi lembut, input radius 14px, tombol 50px, chip pill, NavigationBar indikator solid pink, SnackBar melayang, dialog melengkung. |
| `lib/widgets/common/product_card.dart` | Ilustrasi gradasi sesuai kategori, lingkaran ikon spa, badge kategori, badge stok, harga dalam pill. |
| `lib/widgets/common/empty_state.dart` | Lingkaran gradien dengan bayangan; dibungkus `SingleChildScrollView` agar tidak overflow pada ruang sempit. |
| `lib/widgets/common/app_sidebar.dart` | Indikator aktif solid pink, label tebal untuk menu terpilih. |
| `lib/screens/customer/beranda_screen.dart` | Hero gradien pink berisi sapaan realtime + kolom cari putih. |
| `lib/screens/customer/daftar_produk_screen.dart` | Banner "Koleksi Skincare" dan kartu produk memakai `ProductCard` yang baru. |
| `lib/screens/customer/akun_screen.dart` | Header profil gradien dengan teks putih dan avatar kontras. |
| `lib/screens/auth/masuk_daftar_page.dart` | Logo gradien + bayangan, judul lebih tebal. |
| `lib/screens/admin/admin_dashboard_screen.dart` | 4 kartu statistik responsif di layar lebar, kartu aksi cepat dengan ikon gradien. |

Semua perubahan bersifat presentasional — alur data, Security Rules, dan
kontrak repository tidak berubah. Tombol **Refresh** pada Kelola Produk
memanggil `ProductProvider.refreshData()` yang baru.

Bukti visual: `bukti/tampilan-login.png`, `tampilan-beranda.png`,
`tampilan-daftar-produk.png`, `tampilan-akun.png`,
`tampilan-admin-dashboard.png`, `tampilan-admin-produk.png` (diambil otomatis
oleh `video/scripts/ambil-tampilan.js`). Regresi: `flutter test` 59/59 dan
`uji-crud-produk.js` 5/5 SESUI.

## 10. Pintasan CRUD produk yang mudah ditemukan

Penyegaran visual membuat halaman Beranda lebih menarik, tetapi tombol CRUD
masih tersembunyi di Akun → Dashboard Admin → Kelola Produk. Admin yang sedang
di Beranda tidak melihat akses tersebut, sehingga permintaan berikutnya adalah
"tambahkan button serta dilengkapi (bisa menambahkan produk, edit produk dan
hapus produk)".

Solusinya adalah mendekatkan aksi ke halaman yang paling sering dibuka:

| Berkas | Perubahan |
|---|---|
| `lib/widgets/common/admin_product_shortcuts.dart` **(baru)** | Panel "Alat Administrasi" dengan tiga tombol bertulisan: **Tambah Produk** (`/admin/produk/form`), **Edit Produk** dan **Hapus Produk** (`/admin/produk`). Responsif: tiga kolom di layar lebar, bertumpuk di layar sempit. Edit/Hapus mengarah ke daftar karena produk dipilih per baris. |
| `lib/screens/customer/beranda_screen.dart` | Panel pintasan ditampilkan tepat di bawah hero **hanya untuk admin**; tombol **Kelola Produk** juga ditambahkan di AppBar (desktop: teks lengkap, mobile: "Admin"). Sidebar/bottom nav mendapat pintasan admin indeks 4. |
| `lib/screens/customer/akun_screen.dart` | Menu **Kelola Produk — Tambah, edit, dan hapus produk** ditambahkan setelah Dashboard Admin; sidebar/bottom nav juga diberi pintasan admin. |
| `lib/widgets/common/app_sidebar.dart`, `lib/widgets/common/app_bottom_nav.dart` | Parameter opsional `isAdmin` (default `false`). Indeks 4 hanya muncul untuk admin, sehingga pengguna biasa tetap melihat empat menu seperti sebelumnya. |

Tidak ada perubahan pada repository, Rules, atau alur tulis Firestore —
tombol baru hanya memanggil rute yang sudah ada. Pelanggan tidak melihat
pintasan ini karena `AuthProvider.isAdmin` bernilai `false`.

Verifikasi: `flutter analyze` 0 error/0 warning; `flutter test` 59/59;
`flutter build web --release` OK; `uji-crud-produk.js` **5/5 SESUI**, 0 console
error; `products` kembali berisi 10 dokumen. Screenshot `tampilan-beranda.png`
dan `tampilan-akun.png` diperbarui oleh `ambil-tampilan.js`.

> Catatan operasional: token OAuth `firebase-tools` dapat kedaluwarsa. Bila
> uji integrasi melaporkan "dokumen tidak ditemukan" padahal UI menampilkannya,
> jalankan `firebase firestore:databases:list --project toko-skincare-fec17`
> untuk menyegarkan token sebelum menjalankan skrip uji.
