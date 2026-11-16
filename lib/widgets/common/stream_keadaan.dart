import 'package:flutter/material.dart';
import 'empty_state.dart';

/// Menangani **tiga keadaan StreamBuilder** sesuai modul Minggu 10 (slide 15):
///
/// 1. `ConnectionState.waiting` → indikator loading.
/// 2. `snapshot.hasError`       → pesan ramah (koneksi / Security Rules).
/// 3. data kosong               → `EmptyState`.
///
/// Dipisah menjadi widget sendiri supaya `StreamBuilder` tidak bergantung pada
/// Firebase dan bisa diuji cepat dengan `LayananMemori`.
class StreamKeadaan<T> extends StatelessWidget {
  const StreamKeadaan({
    super.key,
    required this.stream,
    required this.builder,
    required this.isEmpty,
    this.judulKosong = 'Belum ada data',
    this.pesanKosong = 'Data akan muncul di sini setelah ditambahkan',
    this.ikonKosong = Icons.inbox_outlined,
    this.judulError = 'Data belum bisa dimuat',
    this.pesanError =
        'Periksa koneksi internet dan aturan keamanan Firestore, lalu coba lagi.',
  });

  final Stream<T> stream;
  final Widget Function(BuildContext context, T data) builder;
  final bool Function(T data) isEmpty;

  final String judulKosong;
  final String pesanKosong;
  final IconData ikonKosong;
  final String judulError;
  final String pesanError;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        // Selama menunggu snapshot pertama. Bila data lama sudah ada, tetap
        // tampilkan agar tidak berkedip saat stream diperbarui.
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            title: judulError,
            message: pesanError,
            icon: Icons.cloud_off,
          );
        }
        final data = snapshot.data;
        if (data == null || isEmpty(data)) {
          return EmptyState(
            title: judulKosong,
            message: pesanKosong,
            icon: ikonKosong,
          );
        }
        return builder(context, data);
      },
    );
  }
}
