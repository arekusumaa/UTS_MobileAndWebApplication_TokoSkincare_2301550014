import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/product.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/app_bottom_nav.dart';
import '../../widgets/common/app_sidebar.dart';
import '../../widgets/common/empty_state.dart';

class DaftarProdukScreen extends StatefulWidget {
  const DaftarProdukScreen({super.key});

  @override
  State<DaftarProdukScreen> createState() => _DaftarProdukScreenState();
}

class _DaftarProdukScreenState extends State<DaftarProdukScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateTo(int index) {
    switch (index) {
      case 0:
        context.go('/beranda');
        break;
      case 1:
        break;
      case 2:
        context.go('/keranjang');
        break;
      case 3:
        context.go('/akun');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final width = MediaQuery.of(context).size.width;
    final isWeb = width >= AppConstants.mobileBreakpoint;
    final products = productProvider.products;

    final content = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.margin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Cari produk, kategori, kandungan...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: productProvider.setSearchQuery,
                ),
                const SizedBox(height: 16),

                // Filter kategori
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['Semua', ...kategoriProduk].map((kat) {
                      final selected = productProvider.selectedKategori == kat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(kat),
                          selected: selected,
                          onSelected: (_) => productProvider.setKategori(kat),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontSize: 12,
                      ),
                      side: const BorderSide(color: AppColors.border),
                      ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),

                // Filter tipe kulit
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['Semua', ...tipeKulitList].map((tk) {
                      final selected = productProvider.selectedTipeKulit == tk;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(tk),
                          selected: selected,
                          onSelected: (_) => productProvider.setTipeKulit(tk),
                          selectedColor: AppColors.primaryLight,
                          labelStyle: TextStyle(
                            color: selected ? AppColors.primaryDark : AppColors.textPrimary,
                            fontSize: 12,
                          ),
                          side: const BorderSide(color: AppColors.border),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${products.length} produk ditemukan',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        if (products.isEmpty)
          const SliverFillRemaining(
            child: EmptyState(
              title: 'Produk tidak ditemukan',
              message: 'Coba ubah kata kunci atau filter pencarian Anda',
              icon: Icons.search_off,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.margin),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: isWeb ? 250 : 200,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = products[index];
                  return GestureDetector(
                    onTap: () => context.go('/produk/${product.id}'),
                    child: _buildProductCard(product),
                  );
                },
                childCount: products.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );

    if (isWeb) {
      return Scaffold(
        body: Row(
          children: [
            AppSidebar(currentIndex: 1, onTap: (i) => _navigateTo(i)),
            Expanded(
              child: Scaffold(
                appBar: AppBar(title: const Text('Daftar Produk')),
                body: content,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Produk')),
      body: content,
      bottomNavigationBar: AppBottomNav(currentIndex: 1, onTap: (i) => _navigateTo(i)),
    );
  }

  Widget _buildProductCard(product) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: AppColors.backgroundSecondary,
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.image_outlined, size: 40, color: AppColors.textTertiary),
                  ),
                  if (product.isStokHabis)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Stok Habis',
                            style: TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    )
                  else if (product.isStokMenipis)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Menipis',
                            style: TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(product.kategori,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ),
                const SizedBox(height: 6),
                Text(product.nama,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(product.hargaFormatted,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
