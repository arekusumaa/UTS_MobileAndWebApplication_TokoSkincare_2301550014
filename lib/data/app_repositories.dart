import 'data_sources/firestore_data_source.dart';
import 'data_sources/mock_cart_source.dart';
import 'data_sources/mock_order_source.dart';
import 'data_sources/mock_product_source.dart';
import 'data_sources/mock_skin_profile_source.dart';
import 'data_sources/mock_user_source.dart';
import 'data_sync.dart';
import 'repositories/cart_repository.dart';
import 'repositories/order_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/skin_profile_repository.dart';
import 'repositories/user_repository.dart';

/// Titik suntik dependensi (Dependency Injection) untuk seluruh lapisan data.
///
/// Satu `FirestoreDataSource` memenuhi kelima kontrak repository sekaligus,
/// sehingga `users`, `products`, `skin_profiles`, `orders`, dan `carts`
/// berbagi cache dan listener yang sama. Mode `mock()` tetap disediakan untuk
/// widget test, screenshot, dan demonstrasi UTS tanpa koneksi Firebase.
class AppRepositories {
  AppRepositories._({
    required this.products,
    required this.orders,
    required this.skinProfiles,
    required this.users,
    required this.carts,
    required this.sync,
    this.firestore,
  });

  factory AppRepositories.firestore() {
    final sync = DataSync();
    final source = FirestoreDataSource(onChanged: sync.berubah);
    return AppRepositories._(
      products: source,
      orders: source,
      skinProfiles: source,
      users: source,
      carts: source,
      sync: sync,
      firestore: source,
    );
  }

  factory AppRepositories.mock() {
    return AppRepositories._(
      products: MockProductSource(),
      orders: MockOrderSource(),
      skinProfiles: MockSkinProfileSource(),
      users: MockUserSource(),
      carts: MockCartSource(),
      sync: DataSync(),
    );
  }

  /// Konstruktor untuk unit test: cukup ganti repository yang diuji.
  factory AppRepositories.custom({
    required ProductRepository products,
    required OrderRepository orders,
    required SkinProfileRepository skinProfiles,
    required UserRepository users,
    required CartRepository carts,
    DataSync? sync,
  }) {
    return AppRepositories._(
      products: products,
      orders: orders,
      skinProfiles: skinProfiles,
      users: users,
      carts: carts,
      sync: sync ?? DataSync(),
    );
  }

  final ProductRepository products;
  final OrderRepository orders;
  final SkinProfileRepository skinProfiles;
  final UserRepository users;
  final CartRepository carts;
  final DataSync sync;
  final FirestoreDataSource? firestore;

  bool get pakaiFirestore => firestore != null;

  /// Pasang listener auth + kelima listener koleksi. Tidak menunggu jaringan.
  void initialize() => firestore?.initialize();

  /// Isi 10 produk contoh bila collection `products` masih kosong.
  /// Hanya berhasil untuk akun dengan `role == 'admin'`.
  Future<int> seedProductsIfEmpty() async =>
      firestore?.seedProductsIfEmpty() ?? 0;

  Future<void> dispose() async => firestore?.dispose();
}
