import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/filter_produk.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/skin_profile_provider.dart';
import '../../data/models/app_user.dart';
import '../../data/models/product.dart';
import '../../services/layanan_firestore.dart';
import '../../widgets/common/app_bottom_nav.dart';
import '../../widgets/common/app_sidebar.dart';
import '../../widgets/common/logout_button.dart';
import '../../widgets/common/stream_keadaan.dart';
import '../../widgets/product/product_grid.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key, this.layanan});

  /// Injeksi untuk widget test: `LayananMemori()` tanpa koneksi Firebase.
  final LayananToko? layanan;

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  Stream<AppUser?>? _streamProfil;
  Stream<List<Product>>? _streamProduk;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = widget.layanan ?? context.read<LayananToko>();
    _streamProfil ??= service.streamProfilSaya();
    _streamProduk ??= service.streamDaftarProduk();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<SkinProfileProvider>()
          .loadProfile(auth.currentUser?.id ?? '');
    });
  }

  void _navigateTo(int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        context.go('/produk');
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
    final auth = context.watch<AuthProvider>();
    final skinProfile = context.watch<SkinProfileProvider>();
    final width = MediaQuery.of(context).size.width;
    final isWeb = width >= AppConstants.mobileBreakpoint;

    final userName = auth.currentUser?.nama ?? 'Pengguna';

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.margin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sapaan realtime dari users/{uid} (modul Minggu 10, slide 10/16).
          // Profil yang diubah di Console langsung terbaca tanpa login ulang.
          StreamBuilder<AppUser?>(
            stream: _streamProfil,
            builder: (context, snapshot) => Text(
              'Halo, ${snapshot.data?.nama ?? userName}!',
              style: AppTextStyles.judul,
            ),
          ),
          const SizedBox(height: 4),
          Text('Temukan skincare terbaik untuk kulitmu', style: AppTextStyles.keterangan),
          const SizedBox(height: 20),

          // Search bar
          GestureDetector(
            onTap: () => context.go('/produk'),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: AppColors.textSecondary),
                  SizedBox(width: 12),
                  Text(
                    'Cari produk skincare...',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Skin profile banner
          if (skinProfile.profile.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.face_retouching_natural, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lengkapi profil kulit Anda',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Dapatkan rekomendasi yang lebih akurat',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/profil-kulit'),
                    child: const Text('Isi'),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Profil kulit: ${skinProfile.profile.tipeKulit}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/profil-kulit'),
                    child: const Text('Ubah'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Categories
          Text('Kategori', style: AppTextStyles.subjudul),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['Semua', ...kategoriProduk].map((kat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(kat),
                    onPressed: () {
                      context.read<ProductProvider>().setKategori(kat);
                      context.go('/produk');
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Rekomendasi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rekomendasi untuk Anda', style: AppTextStyles.subjudul),
              TextButton(
                onPressed: () => context.go('/produk'),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Daftar rekomendasi dibaca langsung dari `products.snapshots()`.
          // Tiga keadaan StreamBuilder (loading / error / kosong) ditangani
          // StreamKeadaan; filter tipe kulit dihitung di sisi Dart.
          StreamKeadaan<List<Product>>(
            stream: _streamProduk ?? Stream.value(const <Product>[]),
            isEmpty: (daftar) => daftar.isEmpty,
            judulKosong: 'Belum ada produk',
            pesanKosong: 'Produk akan tampil setelah admin menambahkannya',
            ikonKosong: Icons.recommend_outlined,
            builder: (context, daftar) => ProductGrid(
              products: rekomendasiDariStream(
                daftar,
                skinProfile.profile.tipeKulit,
              ),
              onTap: (p) => context.go('/produk/${p.id}'),
            ),
          ),
        ],
      ),
    );

    if (isWeb) {
      return Scaffold(
        body: Row(
          children: [
            AppSidebar(currentIndex: 0, onTap: (i) => _navigateTo(i)),
            Expanded(
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Beranda'),
                  actions: const [LogoutButton()],
                ),
                body: content,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: const [LogoutButton()],
      ),
      body: content,
      bottomNavigationBar: AppBottomNav(currentIndex: 0, onTap: (i) => _navigateTo(i)),
    );
  }
}
