import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/product_provider.dart';

class KelolaProdukScreen extends StatelessWidget {
  const KelolaProdukScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final products = productProvider.allProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.margin),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              onTap: () => context.push('/admin/produk/form', extra: p),
              leading: CircleAvatar(
                backgroundColor: AppColors.backgroundSecondary,
                child: const Icon(Icons.spa, color: AppColors.primary, size: 20),
              ),
              title: Text(p.nama, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              subtitle: Text('${p.kategori} - Stok: ${p.stok} - ${p.hargaFormatted}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                    onPressed: () => context.push('/admin/produk/form', extra: p),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Hapus Produk'),
                          content: Text('Yakin ingin menghapus "${p.nama}"?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                            TextButton(
                              onPressed: () {
                                productProvider.deleteProduct(p.id);
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${p.nama} dihapus')),
                                );
                              },
                              child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/produk/form'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
