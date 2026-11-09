import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/product.dart';
import '../../data/models/skin_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/skin_profile_provider.dart';
import '../../widgets/common/custom_button.dart';

class ProfilKulitScreen extends StatefulWidget {
  const ProfilKulitScreen({super.key});

  @override
  State<ProfilKulitScreen> createState() => _ProfilKulitScreenState();
}

class _ProfilKulitScreenState extends State<ProfilKulitScreen> {
  String? _tipeKulit;
  final Set<String> _selectedConcerns = {};
  final _alergiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<SkinProfileProvider>().profile;
      if (!profile.isEmpty) {
        setState(() {
          _tipeKulit = profile.tipeKulit;
          _selectedConcerns.addAll(profile.concern);
          _alergiController.text = profile.alergi.join(', ');
        });
      }
    });
  }

  @override
  void dispose() {
    _alergiController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final messenger = ScaffoldMessenger.of(context);
    if (_tipeKulit == null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Pilih tipe kulit Anda terlebih dahulu')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final provider = context.read<SkinProfileProvider>();

    provider.saveProfile(
      auth.currentUser?.id ?? '',
      SkinProfile(
        tipeKulit: _tipeKulit!,
        concern: _selectedConcerns.toList(),
        alergi: _alergiController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      ),
    );

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text('Profil kulit berhasil disimpan!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Kulit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.margin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Profil kulit membantu kami memberikan rekomendasi produk yang tepat untuk Anda.',
                      style: AppTextStyles.keterangan,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tipe Kulit
            Text('1. Tipe Kulit Anda?', style: AppTextStyles.subjudul),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tipeKulitList.map((tipe) {
                final selected = _tipeKulit == tipe;
                return ChoiceChip(
                  label: Text(tipe),
                  selected: selected,
                  onSelected: (_) => setState(() => _tipeKulit = tipe),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  side: const BorderSide(color: AppColors.border),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Concern
            Text('2. Concern Utama?', style: AppTextStyles.subjudul),
            const SizedBox(height: 4),
            Text('Pilih satu atau lebih', style: AppTextStyles.caption),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: concernList.map((concern) {
                final selected = _selectedConcerns.contains(concern);
                return FilterChip(
                  label: Text(concern),
                  selected: selected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedConcerns.add(concern);
                      } else {
                        _selectedConcerns.remove(concern);
                      }
                    });
                  },
                  selectedColor: AppColors.primaryLight,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primaryDark : AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  side: const BorderSide(color: AppColors.border),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Alergi
            Text('3. Alergi atau Iritasi?', style: AppTextStyles.subjudul),
            const SizedBox(height: 4),
            Text('Pisahkan dengan koma, kosongkan jika tidak ada', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            TextFormField(
              controller: _alergiController,
              decoration: const InputDecoration(
                hintText: 'Contoh: Fragrance, Alcohol',
                prefixIcon: Icon(Icons.warning_amber),
              ),
            ),
            const SizedBox(height: 32),

            CustomButton(
              label: 'Simpan Profil Kulit',
              icon: Icons.check,
              onPressed: _saveProfile,
            ),
          ],
        ),
      ),
    );
  }
}
