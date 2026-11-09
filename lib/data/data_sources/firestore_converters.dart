import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../models/app_user.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/skin_profile.dart';

/// Konversi model aplikasi <-> dokumen Firestore (Minggu 10).
///
/// Sengaja dipisah dari `FirestoreDataSource` supaya fungsi ini **murni** dan
/// bisa diuji tanpa koneksi Firebase. Tidak ada `FieldValue` di sini:
/// `FieldValue.serverTimestamp()` tidak boleh berada di dalam array/map
/// bertingkat (mis. `items[]` pada pesanan), dan nilainya juga tidak bisa
/// dibaca balik sebagai data. Timestamp server ditambahkan oleh data source
/// pada saat menulis dokumen tingkat atas.
///
/// Semua pembaca toleran terhadap tipe tanggal (`Timestamp`, ISO `String`,
/// atau `DateTime`) dan angka yang kembali sebagai `num`.

int _int(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

String _str(dynamic v, [String fallback = '']) =>
    v is String ? v : (v?.toString() ?? fallback);

List<String> _strList(dynamic v) {
  if (v is List) return v.map((e) => e.toString()).toList();
  return <String>[];
}

DateTime? _date(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
  return null;
}

// ---------------------------------------------------------------------------
// products/{productId}
// ---------------------------------------------------------------------------

Map<String, dynamic> productToFirestore(Product p) => <String, dynamic>{
      'id': p.id,
      'nama': p.nama,
      'kategori': p.kategori,
      'harga': p.harga,
      'stok': p.stok,
      'kandunganAktif': p.kandunganAktif,
      'tipeKulitCocok': p.tipeKulitCocok,
      'paoBulan': p.paoBulan,
      'tanggalBuka':
          p.tanggalBuka == null ? null : Timestamp.fromDate(p.tanggalBuka!),
      'manfaat': p.manfaat,
      'caraPakai': p.caraPakai,
      'imageUrl': p.imageUrl,
    };

Product productFromFirestore(String docId, Map<String, dynamic> d) => Product(
      id: _str(d['id'], docId),
      nama: _str(d['nama']),
      kategori: _str(d['kategori']),
      harga: _int(d['harga']),
      stok: _int(d['stok']),
      kandunganAktif: _strList(d['kandunganAktif']),
      tipeKulitCocok: _strList(d['tipeKulitCocok']),
      paoBulan: _int(d['paoBulan'], 12),
      tanggalBuka: _date(d['tanggalBuka']),
      manfaat: _str(d['manfaat']),
      caraPakai: _str(d['caraPakai']),
      imageUrl: d['imageUrl'] as String?,
    );

// ---------------------------------------------------------------------------
// users/{uid}
// ---------------------------------------------------------------------------

Map<String, dynamic> userToFirestore(AppUser u) => <String, dynamic>{
      'uid': u.id,
      'nama': u.nama,
      'email': u.email,
      'role': u.role,
    };

AppUser userFromFirestore(String uid, Map<String, dynamic> d) => AppUser(
      id: uid,
      nama: _str(d['nama']),
      email: _str(d['email']),
      // Role SELALU berasal dari dokumen Firestore, bukan dari klien.
      role: _str(d['role'], 'pelanggan'),
    );

// ---------------------------------------------------------------------------
// skin_profiles/{uid}
// ---------------------------------------------------------------------------

Map<String, dynamic> skinProfileToFirestore(SkinProfile p) => <String, dynamic>{
      'tipeKulit': p.tipeKulit,
      'concern': p.concern,
      'alergi': p.alergi,
    };

SkinProfile skinProfileFromFirestore(Map<String, dynamic> d) => SkinProfile(
      tipeKulit: _str(d['tipeKulit']),
      concern: _strList(d['concern']),
      alergi: _strList(d['alergi']),
    );

// ---------------------------------------------------------------------------
// carts/{uid}/items/{productId}
// ---------------------------------------------------------------------------

Map<String, dynamic> cartItemToFirestore(CartItem i) => <String, dynamic>{
      'productId': i.product.id,
      'product': productToFirestore(i.product),
      'quantity': i.quantity,
    };

CartItem cartItemFromFirestore(String docId, Map<String, dynamic> d) {
  final rawProduct = d['product'];
  final product = rawProduct is Map
      ? productFromFirestore(
          _str(d['productId'], docId),
          Map<String, dynamic>.from(rawProduct),
        )
      : Product(
          id: _str(d['productId'], docId),
          nama: 'Produk tidak tersedia',
          kategori: '',
          harga: 0,
          stok: 0,
          kandunganAktif: const [],
          tipeKulitCocok: const [],
          paoBulan: 12,
          manfaat: '',
          caraPakai: '',
        );
  return CartItem(product: product, quantity: _int(d['quantity'], 1));
}

// ---------------------------------------------------------------------------
// orders/{orderId}
// ---------------------------------------------------------------------------

Map<String, dynamic> orderToFirestore(Order o, String uid) => <String, dynamic>{
      // uid dipakai Security Rules untuk membatasi pembacaan pelanggan.
      'uid': uid,
      'id': o.id,
      'items': o.items.map(cartItemToFirestore).toList(),
      'total': o.total,
      'status': o.status.name,
      'tanggal': Timestamp.fromDate(o.tanggal),
      'alamat': o.alamat,
      'namaPenerima': o.namaPenerima,
      'telepon': o.telepon,
    };

Order orderFromFirestore(String docId, Map<String, dynamic> d) {
  final rawItems = d['items'];
  final items = rawItems is List
      ? rawItems
          .whereType<Map>()
          .map((m) => cartItemFromFirestore(
                _str(m['productId']),
                Map<String, dynamic>.from(m),
              ))
          .toList()
      : <CartItem>[];

  final statusName = _str(d['status'], 'menunggu');
  final status = OrderStatus.values.firstWhere(
    (s) => s.name == statusName,
    orElse: () => OrderStatus.menunggu,
  );

  return Order(
    id: _str(d['id'], docId),
    items: items,
    total: _int(d['total']),
    status: status,
    tanggal: _date(d['tanggal']) ?? DateTime.now(),
    alamat: _str(d['alamat']),
    namaPenerima: d['namaPenerima'] as String?,
    telepon: d['telepon'] as String?,
  );
}

/// Nama 5 collection sesuai rencana database di proposal UTS.
const List<String> firestoreCollections = <String>[
  'users',
  'products',
  'skin_profiles',
  'orders',
  'carts',
];
