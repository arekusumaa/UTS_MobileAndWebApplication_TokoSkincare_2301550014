import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_store/core/utils/filter_produk.dart';
import 'package:skincare_store/data/data_sources/mock_data.dart';
import 'package:skincare_store/data/models/cart_item.dart';
import 'package:skincare_store/data/models/order.dart';
import 'package:skincare_store/data/models/product.dart';
import 'package:skincare_store/services/layanan_firestore.dart';

/// Unit test lapisan layanan Minggu 10. Seluruhnya memakai `LayananMemori`,
/// jadi tidak ada koneksi Firebase dan test berjalan cepat (sesuai modul,
/// bagian "Masalah umum": injeksi LayananMemori lewat parameter layanan).
void main() {
  Order contohOrder({
    String id = 'ORD-UJI-001',
    List<CartItem>? items,
    OrderStatus status = OrderStatus.menunggu,
  }) =>
      Order(
        id: id,
        items: items ??
            [CartItem(product: MockData.products[0], quantity: 1)],
        total: 55000,
        status: status,
        tanggal: DateTime(2026, 11, 16),
        alamat: 'Jl. Uji No. 1, Bandung',
        namaPenerima: 'Rina',
        telepon: '081234567890',
      );

  group('tandaKeranjang', () {
    test('urutan isi keranjang tidak memengaruhi tanda', () {
      final a = [
        CartItem(product: MockData.products[0], quantity: 1),
        CartItem(product: MockData.products[2], quantity: 2),
      ];
      final b = [
        CartItem(product: MockData.products[2], quantity: 2),
        CartItem(product: MockData.products[0], quantity: 1),
      ];
      expect(tandaKeranjang(a), tandaKeranjang(b));
      expect(tandaKeranjang(a), 'P01:1|P03:2');
    });
  });

  group('cekAturanPesanan (LayananMemori)', () {
    test('keranjang kosong ditolak', () async {
      final l = LayananMemori();
      expect(await l.cekAturanPesanan([]), contains('kosong'));
    });

    test('stok tidak mencukupi ditolak', () async {
      final l = LayananMemori();
      final items = [
        CartItem(product: MockData.products[0], quantity: 999),
      ];
      final hasil = await l.cekAturanPesanan(items);
      expect(hasil, isNotNull);
      expect(hasil, contains('tidak mencukupi'));
    });

    test('pesanan identik yang masih Menunggu ditolak (cegah bentrok)',
        () async {
      final items = [
        CartItem(product: MockData.products[0], quantity: 1),
      ];
      final l = LayananMemori(pesanan: [contohOrder(items: items)]);
      final hasil = await l.cekAturanPesanan(items);
      expect(hasil, isNotNull);
      expect(hasil, contains('Menunggu'));
    });

    test('pesanan identik yang sudah Selesai boleh diajukan lagi', () async {
      final items = [
        CartItem(product: MockData.products[0], quantity: 1),
      ];
      final l = LayananMemori(pesanan: [
        contohOrder(items: items, status: OrderStatus.selesai),
      ]);
      expect(await l.cekAturanPesanan(items), isNull);
    });

    test('isi keranjang valid lolos', () async {
      final l = LayananMemori();
      final items = [
        CartItem(product: MockData.products[0], quantity: 1),
      ];
      expect(await l.cekAturanPesanan(items), isNull);
    });
  });

  group('stream realtime (LayananMemori)', () {
    test('streamDaftarProduk mengirim 10 produk', () async {
      final l = LayananMemori();
      final daftar = await l.streamDaftarProduk().first;
      expect(daftar.length, MockData.products.length);
      expect(daftar.first.nama, 'Glow Cleanser Gel');
    });

    test('streamPesananSaya kosong lalu bertambah setelah tambahPesanan',
        () async {
      final l = LayananMemori();
      final stream = l.streamPesananSaya();
      final pertama = await stream.first;
      expect(pertama, isEmpty);

      // Langganan kedua menerima data awal + pembaruan berikutnya.
      final diterima = <int>[];
      final sub = l.streamPesananSaya().listen((d) => diterima.add(d.length));
      await l.tambahPesanan(contohOrder());
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(diterima, contains(1));
      await sub.cancel();
    });

    test('stream error dilempar bila simulasiError aktif', () async {
      final l = LayananMemori(simulasiError: true);
      await expectLater(
        l.streamPesananSaya().first,
        throwsA(isA<StateError>()),
      );
    });

    test('tambahPesanan menyimpan dokumen baru', () async {
      final l = LayananMemori();
      await l.tambahPesanan(contohOrder(id: 'ORD-UJI-BARU'));
      final semua = await l.streamPesananSaya().first;
      expect(semua.single.id, 'ORD-UJI-BARU');
    });
  });

  group('filter di sisi Dart (tanpa composite index)', () {
    List<Product> sumber() => List<Product>.from(MockData.products);

    test('pencarian cocok pada nama produk', () {
      final hasil = terapkanFilterProduk(sumber(), cari: 'cleanser');
      expect(hasil, isNotEmpty);
      expect(hasil.every((p) =>
          p.nama.toLowerCase().contains('cleanser') ||
          p.kategori.toLowerCase().contains('cleanser') ||
          p.kandunganAktif.any((k) => k.toLowerCase().contains('cleanser'))),
          isTrue);
    });

    test('filter kategori bekerja', () {
      final hasil = terapkanFilterProduk(sumber(), kategori: 'Serum');
      expect(hasil, isNotEmpty);
      expect(hasil.every((p) => p.kategori == 'Serum'), isTrue);
    });

    test('filter tipe kulit bekerja', () {
      final hasil = terapkanFilterProduk(sumber(), tipeKulit: 'Berminyak');
      expect(hasil, isNotEmpty);
      expect(hasil.every((p) => p.tipeKulitCocok.contains('Berminyak')),
          isTrue);
    });

    test('rekomendasi dibatasi maksimal 4', () {
      final hasil = rekomendasiDariStream(sumber(), 'Semua');
      expect(hasil.length, lessThanOrEqualTo(4));
    });
  });
}
