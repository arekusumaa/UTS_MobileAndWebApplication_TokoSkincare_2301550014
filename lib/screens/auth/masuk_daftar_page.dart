import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validasi_auth.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/error_message.dart';

/// Satu halaman untuk dua mode: Masuk dan Daftar (Minggu 9, Latihan 2).
///
/// [_modeDaftar] menentukan judul, label tombol, jumlah kolom, dan operasi
/// FirebaseAuth yang dipanggil. Pola formnya mengikuti Minggu 7:
/// [Form] + [GlobalKey] + [TextFormField] + validator +
/// `AutovalidateMode.onUserInteraction`.
///
/// Berhasil masuk atau daftar TIDAK memanggil Navigator. Perpindahan halaman
/// terjadi otomatis karena `authStateChanges()` memicu ulang redirect
/// [AppRouter] (lihat `lib/screens/auth/cek_status_login.dart`).
class MasukDaftarPage extends StatefulWidget {
  const MasukDaftarPage({super.key, this.modeDaftarAwal = false});

  /// true bila halaman dibuka lewat rute `/register`.
  final bool modeDaftarAwal;

  @override
  State<MasukDaftarPage> createState() => _MasukDaftarPageState();
}

class _MasukDaftarPageState extends State<MasukDaftarPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _modeDaftar = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _modeDaftar = widget.modeDaftarAwal;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// Ganti mode tanpa berpindah rute. Form dan pesan kesalahan di-reset supaya
  /// tidak ada error dari mode sebelumnya yang terbawa.
  void _gantiMode(bool daftar) {
    if (_modeDaftar == daftar) return;
    _formKey.currentState?.reset();
    _namaController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmController.clear();
    context.read<AuthProvider>().clearError();
    setState(() {
      _modeDaftar = daftar;
      _obscurePassword = true;
    });
  }

  Future<void> _kirim() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    if (_modeDaftar) {
      // createUserWithEmailAndPassword otomatis membuat sesi login.
      await auth.register(
        _namaController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      await auth.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
    // Bila gagal, auth.errorMessage berisi terjemahan FirebaseAuthException
    // dan ditampilkan oleh widget ErrorMessage di bawah.
  }

  Widget _judul(String teks) => Text(teks, style: AppTextStyles.isi);

  Widget _kolomEmail() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _judul('Email'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'contoh@email.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: validasiEmail,
          ),
        ],
      );

  Widget _kolomPassword() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _judul('Password'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: 'Minimal 6 karakter',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: validasiPassword,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: _modeDaftar
          ? AppBar(title: const Text('Daftar Akun'))
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: _modeDaftar ? 16 : 48),
                Center(
                  child: Container(
                    width: _modeDaftar ? 56 : 72,
                    height: _modeDaftar ? 56 : 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(
                          _modeDaftar ? 16 : 20),
                    ),
                    child: Icon(
                      Icons.spa,
                      size: _modeDaftar ? 28 : 36,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _modeDaftar ? 'Buat Akun Baru' : 'SkinCare Store',
                    style: AppTextStyles.judul,
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    _modeDaftar
                        ? 'Daftar untuk mulai berbelanja skincare'
                        : 'Temukan skincare yang cocok untuk kulitmu',
                    style: AppTextStyles.keterangan,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: _modeDaftar ? 24 : 32),

                // Kolom Nama hanya ada pada mode Daftar.
                if (_modeDaftar) ...[
                  _judul('Nama Lengkap'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _namaController,
                    decoration: const InputDecoration(
                      hintText: 'Nama lengkap Anda',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        Validators.required(v, fieldName: 'Nama lengkap'),
                  ),
                  const SizedBox(height: 16),
                ],

                _kolomEmail(),
                const SizedBox(height: 16),
                _kolomPassword(),

                // Kolom Ulangi password hanya ada pada mode Daftar.
                if (_modeDaftar) ...[
                  const SizedBox(height: 16),
                  _judul('Ulangi Password'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _obscurePassword,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      hintText: 'Ulangi password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) => validasiUlangiPassword(
                      v,
                      _passwordController.text,
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                if (auth.errorMessage != null)
                  ErrorMessage(
                    message: auth.errorMessage!,
                    onDismiss: auth.clearError,
                  ),
                if (auth.errorMessage != null) const SizedBox(height: 16),
                CustomButton(
                  label: _modeDaftar ? 'Daftar' : 'Masuk',
                  // Nonaktif selama proses agar tidak terkirim dua kali.
                  onPressed: auth.isLoading ? null : _kirim,
                  isLoading: auth.isLoading,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _modeDaftar ? 'Sudah punya akun? ' : 'Belum punya akun? ',
                      style: AppTextStyles.keterangan,
                    ),
                    GestureDetector(
                      onTap: () => _gantiMode(!_modeDaftar),
                      child: Text(
                        _modeDaftar ? 'Masuk' : 'Daftar',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                if (!_modeDaftar) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Akun simulasi Minggu 9',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tekan Daftar untuk membuat akun simulasi baru. '
                          'Akun tersimpan di Firebase Authentication, '
                          'bukan lagi di memori aplikasi. '
                          'Jangan memakai password asli Anda.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
