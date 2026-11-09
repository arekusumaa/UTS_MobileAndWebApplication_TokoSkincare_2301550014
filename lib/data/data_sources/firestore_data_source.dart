import 'dart:async';

// `hide Order`: cloud_firestore ikut mengekspor kelas bernama Order yang
// bertabrakan dengan model pesanan aplikasi kita.
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/skin_profile.dart';
import '../repositories/cart_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/skin_profile_repository.dart';
import '../repositories/user_repository.dart';
import 'firestore_converters.dart';
import 'mock_data.dart';

/// Satu implementasi untuk kelima collection Firestore:
/// `users`, `products`, `skin_profiles`, `orders`, `carts`.
///
/// ## Kenapa ada cache lokal?
/// Kontrak repository warisan Minggu 6 bersifat **sinkron**
/// (`List<Product> getAllProducts()`, `void createOrder(...)`), sedangkan
/// Firestore itu **asinkron** dan berbasis stream. Alih-alih merombak 15
/// halaman UI, kelas ini menyimpan cache yang terus disinkronkan oleh
/// `snapshots()`. Pembacaan tetap sinkron dari cache; penulisan melakukan
/// *optimistic update* pada cache lalu mengirim ke Firestore secara async.
/// Hasilnya: UI responsif, data tetap permanen, dan perubahan dari perangkat
/// lain langsung masuk lewat listener.
///
/// ## Keamanan
/// Role admin **hanya** dibaca dari dokumen `users/{uid}`. Tidak ada lagi
/// pemetaan email hard-code seperti `kAdminEmail` pada Minggu 9.
class FirestoreDataSource implements
    ProductRepository,
    OrderRepository,
    SkinProfileRepository,
    UserRepository,
    CartRepository {
  FirestoreDataSource({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    void Function()? onChanged,
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _onChanged = onChanged;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final void Function()? _onChanged;

  // ---- Cache -------------------------------------------------------------
  final List<Product> _products = [];
  final List<Order> _orders = [];
  final List<CartItem> _cart = [];
  final Map<String, SkinProfile> _profiles = {};
  final Map<String, AppUser> _users = {};
  final Map<String, String> _orderOwner = {};
  final Set<String> _cartDocIds = {};
  bool _productsSnapshotDiterima = false;
  bool _seedPernahDijalankan = false;

  // ---- Langganan ---------------------------------------------------------
  final List<StreamSubscription<dynamic>> _subs = [];
  StreamSubscription<User?>? _authSub;
  String? _uid;
  bool _isAdmin = false;
  bool _siap = false;
  String? _lastError;

  bool get siap => _siap;
  bool get isAdminSaatIni => _isAdmin;
  String? get lastError => _lastError;
  String? get uidSaatIni => _uid;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _db.collection('products');
  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _db.collection('orders');
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _db.collection('users');

  /// Mulai mendengarkan status login. Dipanggil sekali dari `main.dart`
  /// setelah `Firebase.initializeApp()`.
  ///
  /// Sengaja **tidak** di-`await` oleh `main()`: bila Firestore sedang tidak
  /// tersedia, aplikasi tetap harus bisa menampilkan halaman Masuk.
  /// `authStateChanges()` langsung memancarkan status saat ini, sehingga tidak
  /// perlu memanggil `_onAuthChanged` manual (yang justru bisa dobel).
  void initialize() {
    if (_authSub != null) return;
    _siap = true;
    _authSub = _auth.authStateChanges().listen((user) {
      unawaited(_onAuthChanged(user));
    });
    _notify();
  }

  /// Penanda untuk membatalkan proses lama bila status login berubah lagi
  /// selagi `_pastikanProfil` menunggu jaringan.
  int _epoch = 0;

  Future<void> _onAuthChanged(User? user) async {
    final epoch = ++_epoch;
    _hentikanListenerData();
    _products.clear();
    _orders.clear();
    _cart.clear();
    _profiles.clear();
    _users.clear();
    _orderOwner.clear();
    _cartDocIds.clear();
    _productsSnapshotDiterima = false;
    _seedPernahDijalankan = false;
    _uid = user?.uid;
    _isAdmin = false;
    _lastError = null;
    _notify();

    if (user == null) return; // halaman Masuk: tidak ada query yang diizinkan

    // Profil dibuat sekali saat pengguna pertama kali masuk. Rules memaksa
    // role 'pelanggan', sehingga klien tidak bisa mengangkat dirinya sendiri.
    await _pastikanProfil(user);
    if (epoch != _epoch) return; // status login berubah lagi saat menunggu

    _pasangUsersListener(user.uid);
    _pasangProductsListener();
    _pasangProfilKulitListener(user.uid);
    _pasangKeranjangListener(user.uid);
    // Penting: listener pesanan HARUS dipasang untuk pelanggan maupun admin.
    // Query-nya berbeda (lihat _pasangUlangOrdersListener).
    _pasangUlangOrdersListener();
  }

  Future<void> _pastikanProfil(User user) async {
    try {
      final ref = _usersRef.doc(user.uid);
      final snapshot = await ref.get();
      if (snapshot.exists) return;
      await ref.set(<String, dynamic>{
        ...userToFirestore(AppUser(
          id: user.uid,
          nama: user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : (user.email?.split('@').first ?? 'Pengguna'),
          email: user.email ?? '',
          role: 'pelanggan',
        )),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      _setError('Gagal membuat profil pengguna: ${e.code}');
    }
  }

  void _pasangUsersListener(String uid) {
    _tambahSub(_usersRef.doc(uid).snapshots().listen(
      (doc) {
        if (doc.exists && doc.data() != null) {
          _users[uid] = userFromFirestore(uid, doc.data()!);
          final adminBaru = _users[uid]!.isAdmin;
          if (adminBaru != _isAdmin) {
            _isAdmin = adminBaru;
            _pasangUlangOrdersListener();
          }
        } else {
          _users.remove(uid);
          _isAdmin = false;
        }
        _cobaSeedOtomatis();
        _notify();
      },
      onError: (Object e) => _setError('users/$uid: $e'),
    ));
  }

  void _pasangProductsListener() {
    _tambahSub(_productsRef.snapshots().listen(
      (qs) {
        _productsSnapshotDiterima = true;
        _products
          ..clear()
          ..addAll(qs.docs.map(
              (d) => productFromFirestore(d.id, d.data())));
        _cobaSeedOtomatis();
        _notify();
      },
      onError: (Object e) => _setError('products: $e'),
    ));
  }

  void _pasangProfilKulitListener(String uid) {
    _tambahSub(_db.collection('skin_profiles').doc(uid).snapshots().listen(
      (doc) {
        if (doc.exists && doc.data() != null) {
          _profiles[uid] = skinProfileFromFirestore(doc.data()!);
        } else {
          _profiles.remove(uid);
        }
        _notify();
      },
      onError: (Object e) => _setError('skin_profiles/$uid: $e'),
    ));
  }

  void _pasangKeranjangListener(String uid) {
    _tambahSub(_db
        .collection('carts')
        .doc(uid)
        .collection('items')
        .snapshots()
        .listen(
      (qs) {
        _cartDocIds
          ..clear()
          ..addAll(qs.docs.map((d) => d.id));
        _cart
          ..clear()
          ..addAll(qs.docs.map(
              (d) => cartItemFromFirestore(d.id, d.data())));
        _notify();
      },
      onError: (Object e) => _setError('carts/$uid: $e'),
    ));
  }

  /// Query pesanan berbeda untuk admin dan pelanggan. Ini **wajib** supaya
  /// Firestore Rules dapat membuktikan bahwa hasil query hanya berisi dokumen
  /// yang boleh dibaca; query polos `collection('orders')` akan ditolak.
  void _pasangUlangOrdersListener() {
    _hentikanListenerOrders();
    final uid = _uid;
    if (uid == null) return;

    final Query<Map<String, dynamic>> query = _isAdmin
        ? _ordersRef
        : _ordersRef.where('uid', isEqualTo: uid);

    _tambahSub(query.snapshots().listen(
      (qs) {
        _orders.clear();
        _orderOwner.clear();
        for (final d in qs.docs) {
          final data = d.data();
          _orders.add(orderFromFirestore(d.id, data));
          _orderOwner[d.id] = data['uid']?.toString() ?? '';
        }
        // Urutkan di sisi klien agar tidak butuh composite index.
        _orders.sort((a, b) => b.tanggal.compareTo(a.tanggal));
        _notify();
      },
      onError: (Object e) => _setError('orders: $e'),
    ), orders: true);
  }

  final List<StreamSubscription<dynamic>> _orderSubs = [];

  void _tambahSub(StreamSubscription<dynamic> sub, {bool orders = false}) {
    (orders ? _orderSubs : _subs).add(sub);
  }

  void _hentikanListenerOrders() {
    for (final s in _orderSubs) {
      s.cancel();
    }
    _orderSubs.clear();
  }

  void _hentikanListenerData() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _hentikanListenerOrders();
  }

  void _setError(String pesan) {
    _lastError = pesan;
    _notify();
  }

  void _notify() => _onChanged?.call();

  /// Menulis dokumen tingkat atas dengan timestamp server.
  Map<String, dynamic> _denganTimestamp(Map<String, dynamic> data) =>
      <String, dynamic>{...data, 'updatedAt': FieldValue.serverTimestamp()};

  /// Menjalankan operasi tulis secara async sambil menangkap kegagalan aturan.
  void _kirim(Future<void> operasi, String konteks) {
    operasi.catchError((Object e) {
      final kode = e is FirebaseException ? e.code : e.toString();
      _setError('$konteks: $kode');
    });
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
    _authSub = null;
    _hentikanListenerData();
    _siap = false;
  }

  // =======================================================================
  // ProductRepository
  // =======================================================================

  @override
  List<Product> getAllProducts() => List.from(_products);

  @override
  Product? getProductById(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  List<Product> getByKategori(String kategori) {
    if (kategori == 'Semua' || kategori.isEmpty) return List.from(_products);
    return _products.where((p) => p.kategori == kategori).toList();
  }

  @override
  List<Product> searchProducts(String query) {
    if (query.isEmpty) return List.from(_products);
    final q = query.toLowerCase();
    return _products.where((p) {
      return p.nama.toLowerCase().contains(q) ||
          p.kategori.toLowerCase().contains(q) ||
          p.kandunganAktif.any((k) => k.toLowerCase().contains(q));
    }).toList();
  }

  @override
  List<Product> filterByTipeKulit(String tipeKulit) {
    if (tipeKulit.isEmpty || tipeKulit == 'Semua') return List.from(_products);
    return _products.where((p) => p.tipeKulitCocok.contains(tipeKulit)).toList();
  }

  @override
  List<Product> getRekomendasi(String tipeKulit) {
    if (tipeKulit.isEmpty) {
      return _products.where((p) => !p.isStokHabis).take(4).toList();
    }
    final filtered = _products
        .where((p) => p.tipeKulitCocok.contains(tipeKulit) && !p.isStokHabis)
        .toList();
    if (filtered.isEmpty) {
      return _products.where((p) => !p.isStokHabis).take(4).toList();
    }
    return filtered.take(4).toList();
  }

  @override
  List<Product> getStokMenipis() =>
      _products.where((p) => p.stok <= 5).toList();

  @override
  void addProduct(Product product) {
    if (_uid == null) return;
    _products.removeWhere((p) => p.id == product.id);
    _products.add(product);
    _notify();
    _kirim(
      _productsRef.doc(product.id).set(<String, dynamic>{
        ..._denganTimestamp(productToFirestore(product)),
        'createdAt': FieldValue.serverTimestamp(),
      }),
      'Tambah produk',
    );
  }

  @override
  void updateProduct(Product product) {
    if (_uid == null) return;
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx >= 0) _products[idx] = product;
    _notify();
    _kirim(
      _productsRef.doc(product.id).set(
            _denganTimestamp(productToFirestore(product)),
            SetOptions(merge: true),
          ),
      'Ubah produk',
    );
  }

  @override
  void deleteProduct(String id) {
    if (_uid == null) return;
    _products.removeWhere((p) => p.id == id);
    _notify();
    _kirim(_productsRef.doc(id).delete(), 'Hapus produk');
  }

  @override
  void reduceStok(String id, int amount) {
    final idx = _products.indexWhere((p) => p.id == id);
    if (idx < 0 || _uid == null) return;
    final baru = (_products[idx].stok - amount).clamp(0, 999999);
    _products[idx] = _products[idx].copyWith(stok: baru);
    _notify();
    _kirim(
      _productsRef.doc(id).update(<String, dynamic>{
        'stok': baru,
        'updatedAt': FieldValue.serverTimestamp(),
      }),
      'Kurangi stok',
    );
  }

  /// Admin yang pertama kali masuk otomatis mengisi 10 produk contoh.
  /// Dijalankan paling banyak sekali per sesi login agar kegagalan aturan
  /// tidak memicu percobaan berulang tanpa akhir.
  void _cobaSeedOtomatis() {
    if (!_isAdmin || !_productsSnapshotDiterima || _products.isNotEmpty) return;
    if (_seedPernahDijalankan) return;
    _seedPernahDijalankan = true;
    unawaited(_seedAman());
  }

  Future<void> _seedAman() async {
    try {
      await seedProductsIfEmpty();
    } on FirebaseException catch (e) {
      _setError('Isi data awal gagal: ${e.code}');
    } catch (e) {
      _setError('Isi data awal gagal: $e');
    }
  }

  /// Isi 10 produk awal dari `MockData` bila collection masih kosong.
  /// Hanya bisa berhasil untuk admin (lihat `firestore.rules`).
  Future<int> seedProductsIfEmpty() async {
    if (!_isAdmin || _products.isNotEmpty) return 0;
    final batch = _db.batch();
    for (final p in MockData.products) {
      batch.set(_productsRef.doc(p.id), <String, dynamic>{
        ...productToFirestore(p),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return MockData.products.length;
  }

  // =======================================================================
  // OrderRepository
  // =======================================================================

  @override
  List<Order> getAllOrders() => List.from(_orders);

  @override
  List<Order> getOrdersByUser(String userId) => _orders
      .where((o) => _orderOwner[o.id] == userId)
      .toList();

  @override
  Order? getOrderById(String id) {
    for (final o in _orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  @override
  void createOrder(Order order) {
    final uid = _uid;
    if (uid == null) return;
    _orders.removeWhere((o) => o.id == order.id);
    _orders.insert(0, order);
    _orderOwner[order.id] = uid;
    _notify();
    _kirim(
      _ordersRef.doc(order.id).set(<String, dynamic>{
        ...orderToFirestore(order, uid),
        'createdAt': FieldValue.serverTimestamp(),
      }),
      'Buat pesanan',
    );
  }

  @override
  void updateStatus(String orderId, OrderStatus status) {
    if (_uid == null) return;
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) _orders[idx] = _orders[idx].copyWith(status: status);
    _notify();
    _kirim(
      _ordersRef.doc(orderId).update(<String, dynamic>{
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }),
      'Ubah status pesanan',
    );
  }

  // =======================================================================
  // SkinProfileRepository
  // =======================================================================

  @override
  SkinProfile getProfile(String userId) =>
      _profiles[userId] ?? SkinProfile.empty();

  @override
  void saveProfile(String userId, SkinProfile profile) {
    final uid = _uid;
    if (uid == null || uid != userId) return;
    _profiles[userId] = profile;
    _notify();
    _kirim(
      _db.collection('skin_profiles').doc(userId).set(
            _denganTimestamp(skinProfileToFirestore(profile)),
          ),
      'Simpan profil kulit',
    );
  }

  // =======================================================================
  // UserRepository
  // =======================================================================

  @override
  AppUser? getUserById(String uid) => _users[uid];

  @override
  bool isAdmin(String uid) => _users[uid]?.isAdmin ?? false;

  @override
  Future<void> ensureProfile(AppUser user) async {
    // Dokumen sudah dibuat otomatis oleh _pastikanProfil saat login.
    // Metode ini disediakan agar kontrak repository lengkap untuk test.
    final current = _auth.currentUser;
    if (current != null && current.uid == user.id) {
      await _pastikanProfil(current);
    }
  }

  // =======================================================================
  // CartRepository
  // =======================================================================

  @override
  List<CartItem> getCart() => List.unmodifiable(_cart);

  @override
  void saveCart(List<CartItem> items) {
    final uid = _uid;
    if (uid == null) return;
    _cart
      ..clear()
      ..addAll(items);
    _notify();

    final ref = _db.collection('carts').doc(uid).collection('items');
    _kirim(() async {
      final batch = _db.batch();
      final idBaru = <String>{};
      for (final item in items) {
        idBaru.add(item.product.id);
        batch.set(ref.doc(item.product.id), <String, dynamic>{
          ...cartItemToFirestore(item),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      for (final lama in _cartDocIds) {
        if (!idBaru.contains(lama)) batch.delete(ref.doc(lama));
      }
      await batch.commit();
    }(), 'Simpan keranjang');
  }
}
