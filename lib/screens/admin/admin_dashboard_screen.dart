import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../data/models/order.dart';
import '../../widgets/common/logout_button.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final orderProvider = context.watch<OrderProvider>();

    final totalProduk = productProvider.allProducts.length;
    final totalStok = productProvider.allProducts.fold(0, (sum, p) => sum + p.stok);
    final pesananMenunggu = orderProvider.orders
        .where((o) => o.status == OrderStatus.menunggu)
        .length;
    final stokMenipis = productProvider.getStokMenipis();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: const [LogoutButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.margin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width >= 1100 ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  title: 'Total Produk',
                  value: '$totalProduk',
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.primary,
                ),
                _buildStatCard(
                  title: 'Total Stok',
                  value: '$totalStok',
                  icon: Icons.warehouse_outlined,
                  color: Colors.blue,
                ),
                _buildStatCard(
                  title: 'Pesanan Menunggu',
                  value: '$pesananMenunggu',
                  icon: Icons.pending_actions,
                  color: AppColors.warning,
                ),
                _buildStatCard(
                  title: 'Stok Menipis',
                  value: '${stokMenipis.length}',
                  icon: Icons.warning_outlined,
                  color: AppColors.error,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick actions
            Text('Aksi Cepat', style: AppTextStyles.subjudul),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    context,
                    icon: Icons.inventory,
                    title: 'Kelola Produk',
                    onTap: () => context.go('/admin/produk'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionCard(
                    context,
                    icon: Icons.receipt_long,
                    title: 'Kelola Pesanan',
                    onTap: () => context.go('/admin/pesanan'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stok menipis table
            Text('Produk Stok Menipis', style: AppTextStyles.subjudul),
            const SizedBox(height: 12),
            if (stokMenipis.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success),
                    SizedBox(width: 8),
                    Text('Semua stok aman', style: TextStyle(color: AppColors.success)),
                  ],
                ),
              )
            else
              Card(
                child: Column(
                  children: stokMenipis.map((p) {
                    return ListTile(
                      title: Text(p.nama, style: const TextStyle(fontSize: 14)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.isStokHabis ? AppColors.errorLight : AppColors.warningLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Stok: ${p.stok}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: p.isStokHabis ? AppColors.error : AppColors.warning,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            AppColors.gradientSoftB,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gradientA, AppColors.gradientB],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(height: 14),
              Icon(icon, size: 26, color: AppColors.primaryDark),
              const SizedBox(height: 6),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.start),
            ],
          ),
        ),
      ),
    );
  }
}
