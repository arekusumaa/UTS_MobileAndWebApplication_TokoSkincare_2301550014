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
