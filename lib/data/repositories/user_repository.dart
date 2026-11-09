import '../models/app_user.dart';

/// Profil pengguna yang tersimpan di collection `users/{uid}`.
///
/// Sejak Minggu 9 autentikasi ditangani Firebase Auth, jadi repository ini
/// **tidak lagi** menyimpan password atau melakukan login. Perannya murni
/// menyimpan data profil dan — yang terpenting — `role`, yang dipakai
/// Security Rules sebagai dasar otorisasi admin.
abstract class UserRepository {
  AppUser? getUserById(String uid);

  /// Benar bila dokumen `users/{uid}` ada dan `role == 'admin'`.
  bool isAdmin(String uid);

  /// Membuat dokumen profil bila pengguna pertama kali masuk.
  /// Role yang dikirim klien SELALU 'pelanggan'; kenaikan peran hanya bisa
  /// dilakukan langsung di Firebase Console (lihat `docs/minggu-10/`).
  Future<void> ensureProfile(AppUser user);
}
