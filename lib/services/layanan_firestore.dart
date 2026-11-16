import 'dart:async';

// `hide Order`: cloud_firestore ikut mengekspor kelas bernama Order.
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';

import '../data/data_sources/firestore_converters.dart';
import '../data/data_sources/mock_data.dart';
import '../data/models/app_user.dart';
import '../data/models/cart_item.dart';
import '../data/models/order.dart';
import '../data/models/product.dart';

/// Lapisan layanan data Minggu 10.
///
/// Tujuan pemisahan ini (sesuai modul): **widget/UI tidak pernah memanggil
/// `FirebaseFirestore.instance` secara langsung**. Semua pembacaan realtime
/// lewat `Stream<List<...>>` yang dipasang ke `StreamBuilder`, sehingga UI
/// otomatis diperbarui ketika dokumen berubah di Console atau perangkat lain.
///
/// Dua implementasi:
///  * [LayananFirestore] — Cloud Firestore sungguhan (`.snapshots()`).
///  * [LayananMemori]    — data di memori untuk widget test, tanpa koneksi
///                         Firebase. Widget test menyuntikkannya lewat
///                         parameter `layanan` pada halaman.
///
/// Catatan: operasi `users/{uid}` saat login pertama dan auto-seed `products`
/// tetap dijalankan oleh `FirestoreDataSource` (satu implementasi, tidak
/// diduplikasi). Lapisan ini fokus pada **Read realtime + Create pesanan +
/// aturan bisnis sebelum Create**.
abstract class LayananToko {
  /// Seluruh produk. Setara `rooms` pada contoh RoomBook modul.
  Stream<List<Product>> streamDaftarProduk();

  /// Pesanan milik pengguna yang sedang masuk saja.
  /// Query memakai satu `.where('uid', ...)` agar Rules dapat membuktikan
  /// keamanannya; pengurutan dilakukan di Dart supaya tidak butuh
  /// composite index (lihat bagian "Masalah umum" modul).
  Stream<List<Order>> streamPesananSaya();

  /// Profil `users/{uid}` untuk sapaan realtime di Beranda.
  Stream<AppUser?> streamProfilSaya();

  /// Aturan bisnis sebelum dokumen pesanan ditulis.
  /// Mengembalikan `null` bila aman, atau pesan penolakan bila tidak.
  Future<String?> cekAturanPesanan(List<CartItem> items);

  /// Menulis satu dokumen baru ke collection `orders` (operasi Create).
  Future<void> tambahPesanan(Order order);
}

/// Tanda identik untuk mendeteksi pesanan ganda: pasangan `id:jumlah`
/// diurutkan supaya urutan isi keranjang tidak memengaruhi hasil.
String tandaKeranjang(List<CartItem> items) {
  final bagian = items.map((i) => '${i.product.id}:${i.quantity}').toList()
    ..sort();
  return bagian.join('|');
}

String _tandaDokumen(Map<String, dynamic> data) {
  final raw = data['items'];
  if (raw is! List) return '';
  final bagian = raw
      .whereType<Map>()
      .map((m) => '${m['productId'] ?? ''}:${m['quantity'] ?? 0}')
      .toList()
    ..sort();
  return bagian.join('|');
}

// ---------------------------------------------------------------------------
// Implementasi Cloud Firestore
// ---------------------------------------------------------------------------

class LayananFirestore implements LayananToko {
  LayananFirestore({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  @override
  Stream<List<Product>> streamDaftarProduk() =>
      _db.collection('products').snapshots().map(
            (qs) => qs.docs
                .map((d) => productFromFirestore(d.id, d.data()))
                .toList(),
          );

  @override
  Stream<List<Order>> streamPesananSaya() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const <Order>[]);
    return _db
        .collection('orders')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((qs) {
      final daftar = qs.docs
          .map((d) => orderFromFirestore(d.id, d.data()))
          .toList()
        // Urutkan di sisi Dart: menggabungkan where() + orderBy() pada field
        // berbeda memicu error `failed-precondition / requires an index`.
        ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
      return daftar;
    });
  }

  @override
  Stream<AppUser?> streamProfilSaya() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _db.collection('users').doc(uid).snapshots().map(
          (d) => d.exists ? userFromFirestore(uid, d.data()!) : null,
        );
  }

  @override
  Future<String?> cekAturanPesanan(List<CartItem> items) async {
    if (items.isEmpty) return 'Keranjang masih kosong.';

    // Aturan 1 — stok dicek dari server (bukan cache) sebelum dokumen dibuat.
    // Padanan "cegah jadwal bentrok" RoomBook: jangan izinkan pesanan yang
    // tidak bisa dipenuhi oleh master data produk.
    for (final item in items) {
      final doc = await _db.collection('products').doc(item.product.id).get();
      if (!doc.exists) {
        return 'Produk ${item.product.nama} sudah tidak tersedia.';
      }
      final stok = (doc.data()?['stok'] as num?)?.toInt() ?? 0;
      if (stok < item.quantity) {
        return 'Stok ${item.product.nama} tidak mencukupi (tersisa $stok). '
            'Pesanan tidak disimpan.';
      }
    }

    // Aturan 2 — cegah pengajuan ulang pesanan identik yang masih Menunggu.
    // Satu .where() saja; filter status dan isi keranjang dilakukan di Dart.
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'Sesi berakhir. Silakan masuk kembali.';
    final tandaBaru = tandaKeranjang(items);
    final qs = await _db.collection('orders').where('uid', isEqualTo: uid).get();
    for (final d in qs.docs) {
      final data = d.data();
      if (data['status'] != 'menunggu') continue;
      if (_tandaDokumen(data) == tandaBaru) {
        return 'Pesanan dengan isi keranjang yang sama masih berstatus '
            'Menunggu. Tunggu diproses atau ubah isi keranjang.';
      }
    }
    return null;
  }

  @override
  Future<void> tambahPesanan(Order order) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Pengguna belum masuk.');
    await _db.collection('orders').doc(order.id).set(<String, dynamic>{
      ...orderToFirestore(order, uid),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

// ---------------------------------------------------------------------------
// Implementasi memori untuk widget test (tanpa Firebase)
// ---------------------------------------------------------------------------

class LayananMemori implements LayananToko {
  LayananMemori({
    List<Product>? produk,
    List<Order>? pesanan,
    AppUser? profil,
    this.tunda = const Duration(milliseconds: 60),
    this.simulasiError = false,
  })  : _produk = produk ?? List<Product>.from(MockData.products),
        _pesanan = pesanan ?? <Order>[],
        _profil = profil;

  final List<Product> _produk;
  final List<Order> _pesanan;
  final AppUser? _profil;

  /// Jeda sebelum data pertama dikirim. Widget test memakai ini untuk menguji
  /// keadaan `ConnectionState.waiting` pada StreamBuilder.
  final Duration tunda;

  /// Bila true, stream melempar error supaya keadaan `hasError` bisa diuji.
  final bool simulasiError;

  final StreamController<List<Order>> _perubahanPesanan =
      StreamController<List<Order>>.broadcast();

  Stream<T> _aliran<T>(T nilai) async* {
    await Future<void>.delayed(tunda);
    if (simulasiError) {
      throw StateError('Koneksi Firestore terputus (simulasi).');
    }
    yield nilai;
  }

  @override
  Stream<List<Product>> streamDaftarProduk() =>
      _aliran<List<Product>>(List.unmodifiable(_produk));

  @override
  Stream<List<Order>> streamPesananSaya() async* {
    await Future<void>.delayed(tunda);
    if (simulasiError) {
      throw StateError('Koneksi Firestore terputus (simulasi).');
    }
    yield List.unmodifiable(_pesanan);
    // Subscriber tetap mendapat pembaruan setelah pesanan baru ditambahkan.
    yield* _perubahanPesanan.stream;
  }

  @override
  Stream<AppUser?> streamProfilSaya() => _aliran<AppUser?>(_profil);

  @override
  Future<String?> cekAturanPesanan(List<CartItem> items) async {
    if (items.isEmpty) return 'Keranjang masih kosong.';
    for (final item in items) {
      Product? tersedia;
      for (final p in _produk) {
        if (p.id == item.product.id) {
          tersedia = p;
          break;
        }
      }
      if (tersedia == null) {
        return 'Produk ${item.product.nama} sudah tidak tersedia.';
      }
      if (tersedia.stok < item.quantity) {
        return 'Stok ${item.product.nama} tidak mencukupi '
            '(tersisa ${tersedia.stok}). Pesanan tidak disimpan.';
      }
    }
    final tandaBaru = tandaKeranjang(items);
    for (final o in _pesanan) {
      if (o.status != OrderStatus.menunggu) continue;
      if (tandaKeranjang(o.items) == tandaBaru) {
        return 'Pesanan dengan isi keranjang yang sama masih berstatus '
            'Menunggu. Tunggu diproses atau ubah isi keranjang.';
      }
    }
    return null;
  }

  @override
  Future<void> tambahPesanan(Order order) async {
    _pesanan.insert(0, order);
    if (!_perubahanPesanan.isClosed) {
      _perubahanPesanan.add(List.unmodifiable(_pesanan));
    }
  }
}
