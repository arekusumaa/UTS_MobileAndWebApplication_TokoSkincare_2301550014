import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/filter_produk.dart';
import '../../data/models/product.dart';
import '../../providers/product_provider.dart';
import '../../services/layanan_firestore.dart';
import '../../widgets/common/app_bottom_nav.dart';
import '../../widgets/common/app_sidebar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/product_card.dart';

/// Padanan "DaftarRuangPage" pada modul Minggu 10.
///
/// Data produk dibaca realtime dari `products.snapshots()` lewat
/// `StreamBuilder`. Pencarian dan filter tidak diterjemahkan menjadi query
/// Firestore (yang bisa memicu composite index), melainkan dihitung di sisi
/// Dart dari snapshot terbaru. Tiga keadaan stream ditangani eksplisit:
/// waiting, error, dan daftar kosong.
class DaftarProdukScreen extends StatefulWidget {
  const DaftarProdukScreen({super.key, this.layanan});

  /// Injeksi untuk widget test: `LayananMemori()` tanpa koneksi Firebase.
  final LayananToko? layanan;

  @override
  State<DaftarProdukScreen> createState() => _DaftarProdukScreenState();
}

class _DaftarProdukScreenState extends State<DaftarProdukScreen> {
  final _searchController = TextEditingController();
  Stream<List<Product>>? _streamProduk;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Stream dibuat sekali saja. Membuatnya di build() akan membuat
    // StreamBuilder berlangganan ulang setiap kali filter berubah.
    _streamProduk ??=
        (widget.layanan ?? context.read<LayananToko>()).streamDaftarProduk();
  }

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

    final content = StreamBuilder<List<Product>>(
      stream: _streamProduk,
      builder: (context, snapshot) {
        List<Product> products;
        Widget? keadaanKhusus;

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          products = const <Product>[];
          keadaanKhusus = const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          products = const <Product>[];
          keadaanKhusus = const EmptyState(
            title: 'Data belum bisa dimuat',
            message:
                'Periksa koneksi internet dan aturan keamanan Firestore, lalu coba lagi.',
            icon: Icons.cloud_off,
          );
        } else {
          products = terapkanFilterProduk(
            snapshot.data ?? const <Product>[],
            cari: productProvider.searchQuery,
            kategori: productProvider.selectedKategori,
            tipeKulit: productProvider.selectedTipeKulit,
          );
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.margin),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.gradientSoftA,
                            AppColors.gradientSoftB,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.spa_outlined,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Koleksi Skincare',
                                    style: AppTextStyles.subjudul),
                                SizedBox(height: 2),
                                Text(
                                  'Temukan produk yang paling cocok untuk kulitmu',
                                  style: AppTextStyles.keterangan,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Cari produk, kategori, kandungan...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: productProvider.setSearchQuery,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: ['Semua', ...kategoriProduk].map((kat) {
                          final selected =
                              productProvider.selectedKategori == kat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(kat),
                              selected: selected,
                              onSelected: (_) =>
                                  productProvider.setKategori(kat),
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontSize: 12,
                              ),
                              side: const BorderSide(color: AppColors.border),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: ['Semua', ...tipeKulitList].map((tk) {
                          final selected =
                              productProvider.selectedTipeKulit == tk;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(tk),
                              selected: selected,
                              onSelected: (_) =>
                                  productProvider.setTipeKulit(tk),
                              selectedColor: AppColors.primaryLight,
                              labelStyle: TextStyle(
                                color: selected
                                    ? AppColors.primaryDark
                                    : AppColors.textPrimary,
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
            if (keadaanKhusus != null)
              SliverFillRemaining(child: keadaanKhusus)
            else if (products.isEmpty)
              const SliverFillRemaining(
                child: EmptyState(
                  title: 'Produk tidak ditemukan',
                  message: 'Coba ubah kata kunci atau filter pencarian Anda',
                  icon: Icons.search_off,
                ),
              )
            else
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppConstants.margin),
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
      },
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
      bottomNavigationBar:
          AppBottomNav(currentIndex: 1, onTap: (i) => _navigateTo(i)),
    );
  }

  Widget _buildProductCard(Product product) {
    return ProductCard(product: product);
  }
}
