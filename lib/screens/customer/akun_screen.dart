import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/skin_profile_provider.dart';
import '../../widgets/common/app_bottom_nav.dart';
import '../../widgets/common/app_sidebar.dart';

class AkunScreen extends StatelessWidget {
  const AkunScreen({super.key});

  void _navigateTo(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/beranda');
        break;
      case 1:
        context.go('/produk');
        break;
      case 2:
        context.go('/keranjang');
        break;
      case 3:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final skinProfile = context.watch<SkinProfileProvider>();
    final width = MediaQuery.of(context).size.width;
    final isWeb = width >= AppConstants.mobileBreakpoint;

    final user = auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final initials = user.nama
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase();

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.margin),
      child: Column(
        children: [
          // Profile header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: Text(initials, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 12),
                Text(user.nama, style: AppTextStyles.subjudul),
                const SizedBox(height: 4),
                Text(user.email, style: AppTextStyles.keterangan),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.isAdmin ? AppColors.primaryLight : AppColors.successLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.isAdmin ? 'Admin' : 'Pelanggan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: user.isAdmin ? AppColors.primaryDark : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Menu items
          _buildMenuItem(
            icon: Icons.face_retouching_natural,
            title: 'Profil Kulit',
            subtitle: skinProfile.profile.isEmpty
                ? 'Belum diisi'
                : 'Tipe: ${skinProfile.profile.tipeKulit}',
            onTap: () => context.go('/profil-kulit'),
          ),
          _buildMenuItem(
            icon: Icons.receipt_long_outlined,
            title: 'Riwayat Pesanan',
            subtitle: 'Lihat pesanan lampau',
            onTap: () => context.go('/riwayat'),
          ),
          _buildMenuItem(
            icon: Icons.shopping_cart_outlined,
            title: 'Keranjang',
            subtitle: '${cart.totalItems} item',
            onTap: () => context.go('/keranjang'),
          ),
          if (user.isAdmin)
            _buildMenuItem(
              icon: Icons.admin_panel_settings,
              title: 'Dashboard Admin',
              subtitle: 'Kelola produk & pesanan',
              onTap: () => context.go('/admin'),
            ),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Pengaturan',
            subtitle: 'Preferensi aplikasi',
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pengaturan akan tersedia soon')),
              );
            },
          ),
          const SizedBox(height: 16),
          // Logout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                // Navigasi ke Halaman Masuk ditangani auth gate.
                await auth.logout();
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Keluar', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isWeb) {
      return Scaffold(
        body: Row(
          children: [
            AppSidebar(currentIndex: 3, onTap: (i) => _navigateTo(context, i)),
            Expanded(
              child: Scaffold(
                appBar: AppBar(title: const Text('Akun')),
                body: content,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Akun')),
      body: content,
      bottomNavigationBar: AppBottomNav(currentIndex: 3, onTap: (i) => _navigateTo(context, i)),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
