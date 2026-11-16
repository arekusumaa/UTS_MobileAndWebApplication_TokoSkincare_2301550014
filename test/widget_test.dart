import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:skincare_store/data/data_sources/mock_data.dart';
import 'package:skincare_store/data/models/cart_item.dart';
import 'package:skincare_store/data/models/order.dart';
import 'package:skincare_store/providers/product_provider.dart';
import 'package:skincare_store/screens/customer/daftar_produk_screen.dart';
import 'package:skincare_store/screens/customer/riwayat_pesanan_screen.dart';
import 'package:skincare_store/services/layanan_firestore.dart';
import 'package:skincare_store/widgets/common/stream_keadaan.dart';

/// Widget test Minggu 10.
///
/// Seluruh test menyuntikkan `LayananMemori` lewat parameter `layanan` pada
/// halaman, sehingga **tidak ada koneksi Firebase** dan tiga keadaan
/// `StreamBuilder` (waiting / error / kosong) bisa diuji secara deterministik.
/// Ini mengikuti pola `LayananMemori` pada modul (slide 9 & 15).
void main() {
  Order contohOrder(String id) => Order(
        id: id,
        items: [CartItem(product: MockData.products[0], quantity: 1)],
        total: 55000,
        status: OrderStatus.menunggu,
        tanggal: DateTime(2026, 11, 16),
        alamat: 'Jl. Uji No. 1, Bandung',
        namaPenerima: 'Rina',
        telepon: '081234567890',
      );

  Widget bungkus(Widget child) => MaterialApp(home: child);

  group('StreamKeadaan — tiga keadaan StreamBuilder', () {
    testWidgets('waiting menampilkan CircularProgressIndicator',
        (tester) async {
      await tester.pumpWidget(bungkus(
        StreamKeadaan<List<String>>(
          stream: LayananMemori(tunda: const Duration(seconds: 5))
              .streamDaftarProduk()
              .map((p) => p.map((e) => e.id).toList()),
          isEmpty: (d) => d.isEmpty,
          builder: (context, data) => Text('Jumlah: ${data.length}'),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Bersihkan timer jeda LayananMemori agar test tidak menyisakan
      // pending timer saat widget tree dibongkar.
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('error menampilkan pesan ramah, bukan crash', (tester) async {
      await tester.pumpWidget(bungkus(
        StreamKeadaan<List<String>>(
          stream: LayananMemori(
            simulasiError: true,
            tunda: const Duration(milliseconds: 20),
          ).streamDaftarProduk().map((p) => p.map((e) => e.id).toList()),
          isEmpty: (d) => d.isEmpty,
          judulError: 'Data belum bisa dimuat',
          builder: (context, data) => Text('Jumlah: ${data.length}'),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump();

      expect(find.text('Data belum bisa dimuat'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('data kosong menampilkan EmptyState', (tester) async {
      await tester.pumpWidget(bungkus(
        StreamKeadaan<String>(
          stream: Stream.value(''),
          isEmpty: (d) => d.isEmpty,
          judulKosong: 'Belum ada data',
          builder: (context, data) => Text(data),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada data'), findsOneWidget);
    });

    testWidgets('data tersedia diteruskan ke builder', (tester) async {
      await tester.pumpWidget(bungkus(
        StreamKeadaan<String>(
          stream: Stream.value('Halo Firestore'),
          isEmpty: (d) => d.isEmpty,
          builder: (context, data) => Text(data),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Halo Firestore'), findsOneWidget);
    });
  });

  group('RiwayatPesananScreen — streamPesananSaya()', () {
    testWidgets('belum ada pesanan → EmptyState', (tester) async {
      await tester.pumpWidget(bungkus(
        RiwayatPesananScreen(layanan: LayananMemori()),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.text('Belum ada pesanan'), findsOneWidget);
      expect(find.text('ORD-UJI-001'), findsNothing);
    });

    testWidgets('pesanan dari Firestore langsung tampil', (tester) async {
      await tester.pumpWidget(bungkus(
        RiwayatPesananScreen(
          layanan: LayananMemori(pesanan: [contohOrder('ORD-UJI-001')]),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.text('ORD-UJI-001'), findsOneWidget);
      expect(find.text('Belum ada pesanan'), findsNothing);
    });

    testWidgets('dokumen baru muncul tanpa refresh (realtime)', (tester) async {
      final layanan = LayananMemori();
      await tester.pumpWidget(bungkus(
        RiwayatPesananScreen(layanan: layanan),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.text('Belum ada pesanan'), findsOneWidget);

      // Simulasi dokumen `orders/{id}` ditambahkan dari perangkat lain.
      await layanan.tambahPesanan(contohOrder('ORD-REALTIME'));
      await tester.pump();
      await tester.pump();

      expect(find.text('ORD-REALTIME'), findsOneWidget);
      expect(find.text('Belum ada pesanan'), findsNothing);
    });

    testWidgets('stream error ditangani tanpa crash', (tester) async {
      await tester.pumpWidget(bungkus(
        RiwayatPesananScreen(
          layanan: LayananMemori(
            simulasiError: true,
            tunda: const Duration(milliseconds: 20),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump();

      expect(find.text('Data belum bisa dimuat'), findsOneWidget);
    });
  });

  group('DaftarProdukScreen — products.snapshots()', () {
    Widget denganProvider(LayananToko layanan) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ProductProvider()),
          ],
          child: MaterialApp(
            home: DaftarProdukScreen(layanan: layanan),
          ),
        );

    testWidgets('waiting menampilkan loading', (tester) async {
      await tester.pumpWidget(
          denganProvider(LayananMemori(tunda: const Duration(seconds: 5))));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Bersihkan timer jeda LayananMemori (lihat keterangan di atas).
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('sepuluh produk tampil dari stream', (tester) async {
      await tester.pumpWidget(denganProvider(LayananMemori()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(
        find.text('${MockData.products.length} produk ditemukan'),
        findsOneWidget,
      );
      expect(find.text('Daftar Produk'), findsOneWidget);
    });

    testWidgets('pencarian diterapkan di sisi Dart dari snapshot',
        (tester) async {
      await tester.pumpWidget(denganProvider(LayananMemori()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      await tester.enterText(
          find.byType(TextField), MockData.products.first.nama);
      await tester.pump();
      await tester.pump();

      // Hasil menyusut, dan produk yang dicari masih ada di daftar.
      expect(
        find.text('${MockData.products.length} produk ditemukan'),
        findsNothing,
      );
      expect(find.text('1 produk ditemukan'), findsOneWidget);
    });

    testWidgets('error stream menampilkan EmptyState, bukan daftar kosong',
        (tester) async {
      await tester.pumpWidget(denganProvider(LayananMemori(
        simulasiError: true,
        tunda: const Duration(milliseconds: 20),
      )));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump();

      expect(find.text('Data belum bisa dimuat'), findsOneWidget);
    });
  });
}
