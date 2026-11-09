import 'package:flutter/material.dart';

import 'masuk_daftar_page.dart';

/// Rute `/login`. Isi halamannya adalah [MasukDaftarPage] dengan mode Masuk.
///
/// Rute ini tetap dipertahankan (bersama `/register`) agar sitemap UTS dan
/// rekaman demo prototype tidak berubah, meskipun secara visual keduanya kini
/// memakai satu halaman yang sama dengan dua mode.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MasukDaftarPage(modeDaftarAwal: false);
  }
}
