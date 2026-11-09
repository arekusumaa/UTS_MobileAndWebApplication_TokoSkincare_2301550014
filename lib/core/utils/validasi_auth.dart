/// Validasi dan pesan kesalahan khusus halaman autentikasi (Minggu 9).
///
/// Pesan di sini sengaja disamakan persis dengan tabel pada modul supaya
/// hasil uji teman mudah dicocokkan. Validasi umum aplikasi tetap memakai
/// [Validators] di core/utils/validators.dart.

/// Email wajib diisi dan harus berformat email.
String? validasiEmail(String? nilai) {
  final email = nilai?.trim() ?? '';
  if (email.isEmpty) return 'Email wajib diisi';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Format email belum benar';
  }
  return null;
}

/// Password wajib diisi dan minimal 6 karakter (batas minimum Firebase).
String? validasiPassword(String? nilai) {
  final password = nilai ?? '';
  if (password.isEmpty) return 'Password wajib diisi';
  if (password.length < 6) return 'Password minimal 6 karakter';
  return null;
}

/// Kolom ulangi password hanya dipakai pada mode Daftar.
String? validasiUlangiPassword(String? nilai, String password) {
  if (nilai == null || nilai.isEmpty) return 'Ulangi password wajib diisi';
  if (nilai != password) return 'Password tidak sama';
  return null;
}

/// Menerjemahkan [FirebaseAuthException.code] menjadi pesan yang dipahami
/// pengguna. Kode `invalid-credential`, `wrong-password`, dan `user-not-found`
/// sengaja disatukan: project baru mengaktifkan perlindungan enumerasi email,
/// sehingga orang lain tidak bisa menebak email mana yang terdaftar.
String pesanKesalahanAuth(String kode) {
  switch (kode) {
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return 'Email atau password salah';
    case 'invalid-email':
      return 'Format email belum benar';
    case 'email-already-in-use':
      return 'Email sudah terdaftar. Silakan masuk.';
    case 'weak-password':
      return 'Password terlalu lemah, minimal 6 karakter';
    case 'too-many-requests':
      return 'Terlalu banyak percobaan. Coba lagi nanti.';
    case 'network-request-failed':
      return 'Tidak dapat terhubung. Periksa koneksi internet.';
    case 'operation-not-allowed':
      return 'Login email/password belum diaktifkan di Firebase Console';
    case 'user-disabled':
      return 'Akun ini dinonaktifkan. Hubungi administrator.';
    default:
      return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
