import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/models/product.dart';
import 'go_router_refresh_stream.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/customer/beranda_screen.dart';
import '../screens/customer/daftar_produk_screen.dart';
import '../screens/customer/detail_produk_screen.dart';
import '../screens/customer/keranjang_screen.dart';
import '../screens/customer/checkout_screen.dart';
import '../screens/customer/status_pesanan_screen.dart';
import '../screens/customer/akun_screen.dart';
import '../screens/customer/profil_kulit_screen.dart';
import '../screens/customer/riwayat_pesanan_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/kelola_produk_screen.dart';
import '../screens/admin/form_produk_screen.dart';
import '../screens/admin/kelola_pesanan_screen.dart';

class AppRouter {
  /// Halaman yang boleh dibuka tanpa login.
  static const _halamanPublik = {'/login', '/register'};

  static final GoRouter router = GoRouter(
        initialLocation: '/beranda',
        // Status login Firebase dipulihkan secara asynchronous setelah refresh.
        // Listenable ini memaksa redirect dievaluasi ulang saat status berubah.
        refreshListenable: GoRouterRefreshStream(
          FirebaseAuth.instance.authStateChanges(),
        ),
        redirect: (context, state) {
          final sudahMasuk = FirebaseAuth.instance.currentUser != null;
          final diHalamanPublik = _halamanPublik.contains(state.matchedLocation);

          // Otorisasi: seluruh halaman utama tertutup bagi yang belum masuk.
          if (!sudahMasuk && !diHalamanPublik) return '/login';
          // Sudah masuk tidak perlu melihat halaman Masuk/Daftar lagi.
          if (sudahMasuk && diHalamanPublik) return '/beranda';
          return null;
        },
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/register',
            builder: (context, state) => const RegisterScreen(),
          ),
          GoRoute(
            path: '/beranda',
            builder: (context, state) => const BerandaScreen(),
          ),
          GoRoute(
            path: '/produk',
            builder: (context, state) => const DaftarProdukScreen(),
          ),
          GoRoute(
            path: '/produk/:id',
            builder: (context, state) =>
                DetailProdukScreen(productId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/keranjang',
            builder: (context, state) => const KeranjangScreen(),
          ),
          GoRoute(
            path: '/checkout',
            builder: (context, state) => const CheckoutScreen(),
          ),
          GoRoute(
            path: '/status-pesanan',
            builder: (context, state) => const StatusPesananScreen(),
          ),
          GoRoute(
            path: '/akun',
            builder: (context, state) => const AkunScreen(),
          ),
          GoRoute(
            path: '/profil-kulit',
            builder: (context, state) => const ProfilKulitScreen(),
          ),
          GoRoute(
            path: '/riwayat',
            builder: (context, state) => const RiwayatPesananScreen(),
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/produk',
            builder: (context, state) => const KelolaProdukScreen(),
          ),
          GoRoute(
            path: '/admin/produk/form',
            builder: (context, state) => FormProdukScreen(
              product: state.extra is Product ? state.extra as Product : null,
            ),
          ),
          GoRoute(
            path: '/admin/pesanan',
            builder: (context, state) => const KelolaPesananScreen(),
          ),
        ],
        errorBuilder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Halaman tidak ditemukan')),
          body: Center(child: Text('404 - ${state.error}')),
        ),
      );
}
