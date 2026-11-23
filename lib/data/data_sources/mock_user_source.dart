import '../models/app_user.dart';
import '../repositories/user_repository.dart';
import 'mock_data.dart';

/// Padanan in-memory untuk widget test dan mode offline.
/// Tidak menyimpan password — autentikasi sudah ditangani Firebase Auth.
///
/// UID Firebase tidak sama dengan ID statis di [MockData.users] (`U01`,
/// `U02`). Karena itu lookup juga mencoba email pengguna yang sedang login
/// lewat [emailSaatIni]. Closure ini sengaja opsional dan dipanggil malas
/// supaya widget test tetap bisa memakai kelas ini tanpa Firebase.
class MockUserSource implements UserRepository {
  MockUserSource({this.emailSaatIni});

  /// Dipakai mode simulasi di `AppRepositories.mock()`.
  final String? Function()? emailSaatIni;
  final Map<String, AppUser> _users = <String, AppUser>{};

  /// Diisi malas supaya konstruktor tidak mengakses Firebase saat widget test.
  void _isi() {
    if (_users.isNotEmpty) return;
    for (final u in MockData.users) {
      _users[u.id] = u;
      _users[u.email.toLowerCase().trim()] = u;
    }
  }

  @override
  AppUser? getUserById(String uid) {
    _isi();
    final berdasarkanId = _users[uid];
    if (berdasarkanId != null) return berdasarkanId;

    // Mode simulasi memakai UID Firebase yang tidak dikenal MockData.
    final email = emailSaatIni?.call()?.toLowerCase().trim();
    if (email == null || email.isEmpty) return null;
    return _users[email];
  }

  @override
  bool isAdmin(String uid) => getUserById(uid)?.isAdmin ?? false;

  @override
  Future<void> ensureProfile(AppUser user) async {
    _isi();
    _users.putIfAbsent(user.id, () => user);
    _users.putIfAbsent(user.email.toLowerCase().trim(), () => user);
  }
}
