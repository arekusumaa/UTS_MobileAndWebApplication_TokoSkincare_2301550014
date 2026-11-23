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
/// Lengkap dengan pencarian, filter kategori, pengurutan, statistik ringkas,
/// tombol Refresh, dan aksi Tambah / Edit / Hapus yang semuanya menulis ke
/// Firestore.
class KelolaProdukScreen extends StatefulWidget {
  const KelolaProdukScreen({super.key});

  @override
  State<KelolaProdukScreen> createState() => _KelolaProdukScreenState();
}

class _KelolaProdukScreenState extends State<KelolaProdukScreen> {
  final _cariController = TextEditingController();
  String _kategori = 'Semua';
  String _urutan = 'Nama A–Z';

  static const List<String> _pilihanUrutan = <String>[
    'Nama A–Z',
    'Nama Z–A',
    'Harga tertinggi',
    'Harga terendah',
    'Stok terendah',
  ];

  @override
  void dispose() {
    _cariController.dispose();
    super.dispose();
  }

  bool get _adaFilter =>
      _cariController.text.trim().isNotEmpty || _kategori != 'Semua';

  List<Product> _produkTampil(List<Product> sumber) {
    final cari = _cariController.text.trim().toLowerCase();
    final hasil = sumber.where((p) {
      final cocokKategori = _kategori == 'Semua' || p.kategori == _kategori;
      final cocokCari = cari.isEmpty ||
          p.nama.toLowerCase().contains(cari) ||
          p.kategori.toLowerCase().contains(cari) ||
          p.kandunganAktif.any((k) => k.toLowerCase().contains(cari));
      return cocokKategori && cocokCari;
    }).toList();

    switch (_urutan) {
      case 'Nama Z–A':
        hasil.sort((a, b) => b.nama.compareTo(a.nama));
        break;
      case 'Harga tertinggi':
        hasil.sort((a, b) => b.harga.compareTo(a.harga));
        break;
      case 'Harga terendah':
        hasil.sort((a, b) => a.harga.compareTo(b.harga));
        break;
      case 'Stok terendah':
        hasil.sort((a, b) => a.stok.compareTo(b.stok));
        break;
      default:
        hasil.sort((a, b) => a.nama.compareTo(b.nama));
    }
    return hasil;
  }

  void _resetFilter() {
    setState(() {
      _cariController.clear();
      _kategori = 'Semua';
      _urutan = 'Nama A–Z';
    });
  }

  void _refresh(BuildContext context) {
    context.read<ProductProvider>().refreshData();
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text('Data produk disegarkan')),
    );
  }

  void _tambah(BuildContext context) => context.push('/admin/produk/form');

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

  Color _warnaKategori(String kategori) {
    switch (kategori) {
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
    final semua = context.watch<ProductProvider>().allProducts;
    final tampil = _produkTampil(semua);
    final lebar = MediaQuery.of(context).size.width;
    final mobile = lebar < AppConstants.mobileBreakpoint;
    final habis = semua.where((p) => p.isStokHabis).length;
    final menipis = semua.where((p) => p.isStokMenipis).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk'),
        leading: IconButton(
          tooltip: 'Kembali ke Dashboard Admin',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh data produk',
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(context),
          ),
          IconButton(
            tooltip: 'Tambah produk baru',
            icon: const Icon(Icons.add),
            onPressed: () => _tambah(context),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- Panel ringkasan + aksi utama --------------------------------
          Container(
            margin: const EdgeInsets.fromLTRB(
              AppConstants.margin, AppConstants.margin, AppConstants.margin, 12,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryLight, AppColors.backgroundSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.inventory_2_outlined,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Katalog Produk', style: AppTextStyles.subjudul),
                          const SizedBox(height: 2),
                          const Text(
                            'Tambah, ubah, atau hapus produk skincare',
                            style: AppTextStyles.keterangan,
                          ),
                        ],
                      ),
                    ),
                    Tooltip(
                      message: 'Tambah produk baru',
                      child: ElevatedButton.icon(
                        onPressed: () => _tambah(context),
                        icon: const Icon(Icons.add),
                        label: Text(mobile ? 'Tambah' : 'Tambah Produk Baru'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _statChip(Icons.inventory_outlined, '${semua.length}', 'Produk',
                        AppColors.primary),
                    const SizedBox(width: 8),
                    _statChip(Icons.warning_amber_outlined, '$menipis', 'Stok menipis',
                        AppColors.warning),
                    const SizedBox(width: 8),
                    _statChip(Icons.block_outlined, '$habis', 'Stok habis',
                        AppColors.error),
                  ],
                ),
              ],
            ),
          ),

          // ---- Pencarian, filter, dan pengurutan ---------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.margin),
            child: Column(
              children: [
                TextField(
                  controller: _cariController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cari nama, kategori, atau kandungan produk…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _cariController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Hapus pencarian',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _cariController.clear();
                              setState(() {});
                            },
                          ),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.backgroundSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['Semua', ...kategoriProduk].map((kat) {
                            final aktif = _kategori == kat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(kat),
                                selected: aktif,
                                onSelected: (_) =>
                                    setState(() => _kategori = kat),
                                selectedColor: AppColors.primaryLight,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButton<String>(
                        value: _urutan,
                        isDense: true,
                        underline: const SizedBox.shrink(),
                        items: _pilihanUrutan
                            .map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) => setState(() => _urutan = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Menampilkan ${tampil.length} dari ${semua.length} produk',
                      style: AppTextStyles.caption,
                    ),
                    const Spacer(),
                    if (_adaFilter)
                      TextButton.icon(
                        onPressed: _resetFilter,
                        icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                        label: const Text('Reset filter'),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ---- Daftar produk ------------------------------------------------
          Expanded(
            child: tampil.isEmpty
                ? _emptyState(semua.isEmpty)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppConstants.margin, 4, AppConstants.margin, AppConstants.margin,
                    ),
                    itemCount: tampil.length,
                    itemBuilder: (context, index) =>
                        _produkCard(context, tampil[index], mobile),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String nilai, String label, Color warna) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: warna, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nilai,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: warna)),
                  Text(label, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _produkCard(BuildContext context, Product p, bool mobile) {
    final warna = _warnaKategori(p.kategori);
    final warnaStok = p.isStokHabis
        ? AppColors.error
        : p.isStokMenipis
            ? AppColors.warning
            : AppColors.success;
    final labelStok = p.isStokHabis
        ? 'Habis'
        : p.isStokMenipis
            ? 'Menipis'
            : 'Aman';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: warna.withValues(alpha: 0.25),
              child: Icon(Icons.spa, color: warna, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => _edit(context, p),
                title: Text(
                  p.nama,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${p.kategori}  •  ${p.hargaFormatted}  •  Stok ${p.stok}',
                  style: AppTextStyles.keterangan,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: warnaStok.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                labelStok,
                style: TextStyle(fontSize: 12, color: warnaStok, fontWeight: FontWeight.w600),
              ),
            ),
            if (!mobile) const SizedBox(width: 4),
            Tooltip(
              message: 'Edit ${p.nama}',
              child: TextButton.icon(
                onPressed: () => _edit(context, p),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ),
            Tooltip(
              message: 'Hapus ${p.nama}',
              child: TextButton.icon(
                onPressed: () => _konfirmasiHapus(context, p),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Hapus'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(bool benarBenarKosong) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              benarBenarKosong ? Icons.inventory_2_outlined : Icons.search_off,
              size: 56,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              benarBenarKosong ? 'Belum ada produk' : 'Produk tidak ditemukan',
              style: AppTextStyles.subjudul,
            ),
            const SizedBox(height: 4),
            Text(
              benarBenarKosong
                  ? 'Tambahkan produk pertama lewat tombol di atas.'
                  : 'Coba kata kunci atau kategori lain.',
              style: AppTextStyles.keterangan,
              textAlign: TextAlign.center,
            ),
            if (_adaFilter) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _resetFilter,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Reset filter'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
