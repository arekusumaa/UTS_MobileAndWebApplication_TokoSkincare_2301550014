import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_store/data/data_sources/firestore_converters.dart';
import 'package:skincare_store/data/models/app_user.dart';
import 'package:skincare_store/data/models/cart_item.dart';
import 'package:skincare_store/data/models/order.dart';
import 'package:skincare_store/data/models/product.dart';
import 'package:skincare_store/data/models/skin_profile.dart';

Product _produk() => const Product(
      id: 'P01',
      nama: 'Glow Cleanser Gel',
      kategori: 'Cleanser',
      harga: 45000,
      stok: 12,
      kandunganAktif: ['Niacinamide', 'Green Tea'],
      tipeKulitCocok: ['Berminyak', 'Kombinasi'],
      paoBulan: 12,
      manfaat: 'Membersihkan kulit',
      caraPakai: 'Pagi dan malam',
    );

void main() {
  group('Nama collection', () {
    test('tepat 5 collection sesuai proposal UTS', () {
      expect(firestoreCollections, hasLength(5));
      expect(
        firestoreCollections,
        containsAllInOrder(<String>[
          'users',
          'products',
          'skin_profiles',
          'orders',
          'carts',
        ]),
      );
    });
  });

  group('products/{productId}', () {
    test('round trip menjaga seluruh field', () {
      final map = productToFirestore(_produk());
      final balik = productFromFirestore('P01', map);

      expect(balik.id, 'P01');
      expect(balik.nama, 'Glow Cleanser Gel');
      expect(balik.harga, 45000);
      expect(balik.stok, 12);
      expect(balik.kandunganAktif, ['Niacinamide', 'Green Tea']);
      expect(balik.tipeKulitCocok, ['Berminyak', 'Kombinasi']);
      expect(balik.paoBulan, 12);
      expect(balik.manfaat, 'Membersihkan kulit');
      expect(balik.caraPakai, 'Pagi dan malam');
      expect(balik.tanggalBuka, isNull);
    });

    test('tanggalBuka jadi Timestamp dan bisa dibaca balik', () {
      final tanggal = DateTime(2026, 9, 15);
      final map = productToFirestore(_produk().copyWith(tanggalBuka: tanggal));
      expect(map['tanggalBuka'], isA<Timestamp>());
      // Timestamp selalu UTC, jadi bandingkan lewat konversi yang sama.
      expect(
        productFromFirestore('P01', map).tanggalBuka,
        Timestamp.fromDate(tanggal).toDate(),
      );
    });

    test('pembaca toleran terhadap angka num dan tanggal ISO string', () {
      final balik = productFromFirestore('DOC-9', <String, dynamic>{
        'nama': 'Toner',
        'harga': 55000.0,
        'stok': 8.0,
        'paoBulan': '6',
        'tanggalBuka': '2026-01-02T00:00:00.000',
      });
      expect(balik.id, 'DOC-9'); // fallback ke docId bila field id hilang
      expect(balik.harga, 55000);
      expect(balik.stok, 8);
      expect(balik.paoBulan, 6);
      expect(balik.tanggalBuka, DateTime(2026, 1, 2));
    });
  });

  group('users/{uid}', () {
    test('role dibaca dari dokumen, bukan dari klien', () {
      const user = AppUser(
        id: 'UID-1',
        nama: 'Admin Toko',
        email: 'admin@skincare.id',
        role: 'admin',
      );
      final map = userToFirestore(user);
      final balik = userFromFirestore('UID-1', map);
      expect(balik.isAdmin, isTrue);
      expect(balik.email, 'admin@skincare.id');
    });

    test('role kosong jatuh ke pelanggan', () {
      expect(
        userFromFirestore('UID-2', <String, dynamic>{'nama': 'Rina'}).isPelanggan,
        isTrue,
      );
    });
  });

  group('skin_profiles/{uid}', () {
    test('round trip', () {
      const profil = SkinProfile(
        tipeKulit: 'Berminyak',
        concern: ['Jerawat', 'Pori Besar'],
        alergi: ['Fragrance'],
      );
      final balik = skinProfileFromFirestore(skinProfileToFirestore(profil));
      expect(balik.tipeKulit, 'Berminyak');
      expect(balik.concern, ['Jerawat', 'Pori Besar']);
      expect(balik.alergi, ['Fragrance']);
      expect(balik.isEmpty, isFalse);
    });
  });

  group('carts/{uid}/items/{productId}', () {
    test('productId sama dengan nama dokumen', () {
      final item = CartItem(product: _produk(), quantity: 3);
      final map = cartItemToFirestore(item);
      expect(map['productId'], 'P01');
      expect(map['quantity'], 3);

      final balik = cartItemFromFirestore('P01', map);
      expect(balik.quantity, 3);
      expect(balik.product.nama, 'Glow Cleanser Gel');
    });

    test('dokumen tanpa data produk tidak crash', () {
      final balik = cartItemFromFirestore('P99', <String, dynamic>{
        'productId': 'P99',
        'quantity': 1,
      });
      expect(balik.product.nama, 'Produk tidak tersedia');
      expect(balik.product.stok, 0);
    });
  });

  group('orders/{orderId}', () {
    test('uid, items, status dan tanggal tersimpan', () {
      final order = Order(
        id: 'ORD-1',
        items: [CartItem(product: _produk(), quantity: 2)],
        total: 90000,
        status: OrderStatus.menunggu,
        tanggal: DateTime(2026, 11, 9, 10, 30),
        alamat: 'Jl. Melati No. 5',
        namaPenerima: 'Rina',
        telepon: '08123456789',
      );
      final map = orderToFirestore(order, 'UID-PELANGGAN');
      expect(map['uid'], 'UID-PELANGGAN'); // dipakai Security Rules
      expect(map['status'], 'menunggu');
      expect(map['tanggal'], isA<Timestamp>());
      expect(map['items'], isA<List>());

      final balik = orderFromFirestore('ORD-1', map);
      expect(balik.total, 90000);
      expect(balik.items.single.quantity, 2);
      expect(balik.items.single.product.id, 'P01');
      expect(balik.status, OrderStatus.menunggu);
      expect(balik.alamat, 'Jl. Melati No. 5');
    });

    test('status tidak dikenal jatuh ke menunggu', () {
      final balik = orderFromFirestore('ORD-2', <String, dynamic>{
        'status': 'status-aneh',
        'total': 1000,
      });
      expect(balik.status, OrderStatus.menunggu);
      expect(balik.items, isEmpty);
    });
  });
}
