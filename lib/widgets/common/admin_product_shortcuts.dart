import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

/// Pintasan kelola produk yang ditampilkan hanya untuk admin.
///
/// Tombolnya sengaja eksplisit (Tambah / Edit / Hapus) supaya admin tidak
/// perlu menebak ikon atau mencari menu di halaman Akun. Edit dan Hapus
/// mengarah ke halaman Kelola Produk karena aksinya dipilih per baris produk.
class AdminProductShortcuts extends StatelessWidget {
  const AdminProductShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gradientSoftA, AppColors.gradientSoftB],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
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
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alat Administrasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Kelola katalog produk skincare Anda',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final tombol = <Widget>[
                _ShortcutButton(
                  icon: Icons.add_circle_outline,
                  label: 'Tambah Produk',
                  caption: 'Buat produk baru',
                  primary: true,
                  onTap: () => context.go('/admin/produk/form'),
                ),
                _ShortcutButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit Produk',
                  caption: 'Ubah data, harga, dan stok',
                  onTap: () => context.go('/admin/produk'),
                ),
                _ShortcutButton(
                  icon: Icons.delete_outline,
                  label: 'Hapus Produk',
                  caption: 'Hapus dari katalog',
                  destructive: true,
                  onTap: () => context.go('/admin/produk'),
                ),
              ];

              if (constraints.maxWidth >= 620) {
                return Row(
                  children: [
                    for (var i = 0; i < tombol.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: tombol[i]),
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  for (var i = 0; i < tombol.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    tombol[i],
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ShortcutButton extends StatelessWidget {
  const _ShortcutButton({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
    this.primary = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;
  final bool primary;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final warna = destructive ? AppColors.error : AppColors.primary;
    final isi = Row(
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                style: TextStyle(
                  fontSize: 11,
                  color: primary ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_ios, size: 13),
      ],
    );

    final bentuk = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    final button = primary
        ? ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 58),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: bentuk,
              alignment: Alignment.centerLeft,
            ),
            child: isi,
          )
        : OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: warna,
              minimumSize: const Size(0, 58),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: bentuk,
              alignment: Alignment.centerLeft,
              side: BorderSide(
                color: destructive
                    ? AppColors.error.withValues(alpha: 0.35)
                    : AppColors.borderSecondary,
              ),
            ),
            child: isi,
          );

    return Tooltip(message: label, child: button);
  }
}
