import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/product.dart';

/// Kartu produk yang dipakai di Beranda, Daftar Produk, dan halaman lain.
/// Tampilan diperbarui dengan ilustrasi gradasi, badge kategori, dan harga
/// dalam pill agar lebih hidup tanpa mengubah perilaku klik.
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  Color _warnaKategori() {
    switch (product.kategori) {
      case 'Cleanser':
        return AppColors.cleanser;
      case 'Toner':
        return AppColors.toner;
      case 'Serum':
        return AppColors.serum;
      case 'Moisturizer':
        return AppColors.moisturizer;
      case 'Sunscreen':
        return AppColors.sunscreen;
      case 'Mask':
        return AppColors.primary;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final warna = _warnaKategori();
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ilustrasi produk berbasis gradasi + ikon kategori.
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      warna.withValues(alpha: 0.22),
                      AppColors.gradientSoftB,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.75),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.spa_outlined, size: 38, color: warna),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          product.kategori,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: warna,
                          ),
                        ),
                      ),
                    ),
                    if (product.isStokHabis || product.isStokMenipis)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: product.isStokHabis
                                ? AppColors.error
                                : AppColors.warning,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            product.isStokHabis ? 'Stok Habis' : 'Menipis',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nama,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          product.hargaFormatted,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_forward_ios,
                          size: 12, color: AppColors.textTertiary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
