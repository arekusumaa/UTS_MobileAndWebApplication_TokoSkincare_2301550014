import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/product.dart';
import '../../providers/product_provider.dart';

/// Halaman admin untuk mengelola katalog produk.
///
/// Tiga aksi sengaja dibuat terlihat eksplisit (bukan hanya ikon kecil):
/// tombol **Tambah Produk Baru** di header, serta tombol bertulisan
/// **Edit** dan **Hapus** pada setiap baris produk.
class KelolaProdukScreen extends StatelessWidget {
  const KelolaProdukScreen({super.key});

  void _tambah(BuildContext context) =>
      context.push('/admin/produk/form');

  void _edit(BuildContext context, Product product) =>
      context.push('/admin/produk/form', extra: product);

  void _konfirmasiHapus(BuildContext context, Product product) {
    final provider = context.read<ProductProvider>();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin ingin menghapus "${product.nama}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteProduct(product.id);
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(
                SnackBar(content: Text('${product.nama} dihapus')),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().allProducts;
    final lebar = MediaQuery.of(context).size.width;
    final tombolKecil = lebar < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk'),
        leading: IconButton(
          tooltip: 'Kembali ke Dashboard Admin',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- Panel aksi utama -------------------------------------------
          Container(
            margin: const EdgeInsets.all(AppConstants.margin),
            padding: const EdgeInsets.all(AppConstants.margin),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    color: AppColors.primaryDark, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Katalog Produk', style: AppTextStyles.subjudul),
                      const SizedBox(height: 2),
                      Text(
                        '${products.length} produk  •  Tambah, ubah, atau hapus produk skincare',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Tooltip(
                  message: 'Tambah produk baru',
                  child: ElevatedButton.icon(
                    onPressed: () => _tambah(context),
                    icon: const Icon(Icons.add),
                    label: Text(tombolKecil ? 'Tambah' : 'Tambah Produk Baru'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 44),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---- Daftar produk dengan aksi bertulisan -----------------------
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                AppConstants.margin,
                0,
                AppConstants.margin,
                AppConstants.margin,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.backgroundSecondary,
                          child: const Icon(Icons.spa,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            onTap: () => _edit(context, p),
                            title: Text(
                              p.nama,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              '${p.kategori}  •  Stok: ${p.stok}  •  ${p.hargaFormatted}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                        Tooltip(
                          message: 'Edit ${p.nama}',
                          child: TextButton.icon(
                            onPressed: () => _edit(context, p),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ),
                        Tooltip(
                          message: 'Hapus ${p.nama}',
                          child: TextButton.icon(
                            onPressed: () => _konfirmasiHapus(context, p),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Hapus'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
