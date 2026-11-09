import '../models/app_user.dart';
import '../repositories/user_repository.dart';
import 'mock_data.dart';

/// Padanan in-memory untuk widget test dan mode offline.
/// Tidak menyimpan password — autentikasi sudah ditangani Firebase Auth.
class MockUserSource implements UserRepository {
  final Map<String, AppUser> _users = {
    for (final u in MockData.users) u.id: u,
  };

  @override
  AppUser? getUserById(String uid) => _users[uid];

  @override
  bool isAdmin(String uid) => _users[uid]?.isAdmin ?? false;

  @override
  Future<void> ensureProfile(AppUser user) async {
    _users.putIfAbsent(user.id, () => user);
  }
}
