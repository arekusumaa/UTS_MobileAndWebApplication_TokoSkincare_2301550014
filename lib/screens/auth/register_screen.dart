import 'package:flutter/material.dart';

import 'masuk_daftar_page.dart';

/// Rute `/register`. Isi halamannya adalah [MasukDaftarPage] dengan mode
/// Daftar, sehingga tombol "Masuk" di dalam halaman dapat berpindah mode
/// tanpa Navigator.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MasukDaftarPage(modeDaftarAwal: true);
  }
}
