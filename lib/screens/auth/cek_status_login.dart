import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../router/app_router.dart';

/// Gerbang autentikasi: padanan `home: CekStatusLogin()` pada modul.
///
/// [FirebaseAuth.authStateChanges] memberi kabar setiap kali status login
/// berubah. Selama status pertama belum datang (Firebase sedang memulihkan
/// sesi dari penyimpanan browser), ditampilkan indikator proses agar router
/// tidak salah mengarahkan ke halaman Masuk.
///
/// [halamanAwal] disediakan untuk widget test yang tidak boleh memanggil
/// Firebase, sesuai catatan "Masalah umum" pada modul.
class CekStatusLogin extends StatelessWidget {
  const CekStatusLogin({super.key, this.halamanAwal});

  final Widget? halamanAwal;

  @override
  Widget build(BuildContext context) {
    if (halamanAwal != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: halamanAwal,
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Gagal memeriksa status login.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }

        // Pemilihan halaman Masuk vs Halaman Utama dilakukan oleh redirect
        // pada AppRouter, yang membaca FirebaseAuth.instance.currentUser dan
        // dipicu ulang oleh GoRouterRefreshStream. Jadi tidak ada Navigator
        // di dalam kode login.
        return MaterialApp.router(
          title: 'SkinCare Store',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
