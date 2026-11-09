import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

/// Tombol Keluar untuk app bar.
///
/// Tidak memanggil Navigator: begitu FirebaseAuth.signOut() selesai,
/// authStateChanges() memberi kabar ke CekStatusLogin dan redirect GoRouter,
/// sehingga halaman kembali ke Halaman Masuk dengan sendirinya.
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Keluar',
      icon: const Icon(Icons.logout),
      onPressed: () async {
        await context.read<AuthProvider>().logout();
      },
    );
  }
}
