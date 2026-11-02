import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../data/models/product.dart';

class DetailProdukScreen extends StatelessWidget {
  final String productId;

  const DetailProdukScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final productProvider = context.read<ProductProvider>();
    final cart = context.read<CartProvider>();
    final product = productProvider.getProductById(productId);

    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Produk tidak ditemukan')),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final isWeb = width >= AppConstants.tabletBreakpoint;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.nama),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.go('/keranjang'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.margin),
        child: isWeb
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: _buildImagePlaceholder()),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildInfo(context, product, cart)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImagePlaceholder(),
                  const SizedBox(height: 16),
                  _buildInfo(context, product, cart),
                ],
              ),
      ),
      bottomNavigationBar: _buildBottomBar(context, product, cart),
    );
  }

  Widget _buildImagePlaceholder() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.spa, size: 64, color: AppColors.textTertiary),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, Product product, cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildBadge(product.kategori, AppColors.backgroundSecondary, AppColors.textSecondary),
            const SizedBox(width: 8),
            ...product.tipeKulitCocok.map(
              (tk) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _buildBadge(tk, AppColors.backgroundTertiary, AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(product.nama, style: AppTextStyles.judul),
        const SizedBox(height: 4),
        Text(product.hargaFormatted,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.primary)),
        const SizedBox(height: 12),
        _buildStokIndicator(product),
        const SizedBox(height: 20),
        _buildSection('Kandungan Aktif',
            product.kandunganAktif.map((k) => _buildChip(k)).toList()),
        const SizedBox(height: 16),
        _buildSectionText('Manfaat', product.manfaat),
        const SizedBox(height: 16),
        _buildSectionText('Cara Pakai', product.caraPakai),
        const SizedBox(height: 16),
        _buildPaoInfo(product),
      ],
    );
  }

  Widget _buildBadge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w400)),
    );
  }

  Widget _buildStokIndicator(Product product) {
    Color color;
    String text;
    if (product.isStokHabis) {
      color = AppColors.error;
      text = 'Stok Habis';
    } else if (product.isStokMenipis) {
      color = AppColors.warning;
      text = 'Stok Menipis (${product.stok})';
    } else {
      color = AppColors.success;
      text = 'Stok: ${product.stok}';
    }
    return Row(
      children: [
        Icon(Icons.inventory_2_outlined, size: 18, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.subjudul),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: children),
      ],
    );
  }

  Widget _buildSectionText(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.subjudul),
        const SizedBox(height: 6),
        Text(body, style: AppTextStyles.isi),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
    );
  }

  Widget _buildPaoInfo(Product product) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Masa Pakai (PAO)', style: AppTextStyles.subjudul),
            ],
          ),
          const SizedBox(height: 8),
          Text('Masa pakai setelah dibuka: ${product.paoBulan} bulan',
              style: AppTextStyles.isi),
          if (product.tanggalBuka != null) ...[
            const SizedBox(height: 4),
            Text(
              'Dibuka pada: ${product.tanggalBuka!.day}/${product.tanggalBuka!.month}/${product.tanggalBuka!.year}',
              style: AppTextStyles.keterangan,
            ),
            if (product.isPaoExpired)
              const Text(
                'Perhatian: PAO akan kadaluarsa segera!',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.error),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, Product product, cart) {
    final isStokHabis = product.isStokHabis;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isStokHabis
                  ? null
                  : () {
                      cart.addToCart(product);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.nama} ditambah ke keranjang'),
                          action: SnackBarAction(
                            label: 'Lihat',
                            onPressed: () => context.go('/keranjang'),
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Keranjang'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: isStokHabis
                  ? null
                  : () {
                      cart.addToCart(product);
                      context.go('/checkout');
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 48),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Beli Sekarang'),
            ),
          ),
        ],
      ),
    );
  }
}
