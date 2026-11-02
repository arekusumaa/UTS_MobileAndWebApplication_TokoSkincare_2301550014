import '../models/app_user.dart';
import '../repositories/user_repository.dart';
import 'mock_data.dart';

class MockUserSource implements UserRepository {
  final List<AppUser> _users = List.from(MockData.users);
  final Map<String, String> _passwords = {
    for (final u in MockData.users) u.email: MockData.password,
  };

  @override
  AppUser? login(String email, String password) {
    if (_passwords[email] == password) {
      try {
        return _users.firstWhere((u) => u.email == email);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  void register(AppUser user, String password) {
    if (getUserByEmail(user.email) != null) {
      throw Exception('Email sudah terdaftar');
    }
    _users.add(user);
    _passwords[user.email] = password;
  }

  @override
  AppUser? getUserByEmail(String email) {
    try {
      return _users.firstWhere((u) => u.email == email);
    } catch (e) {
      return null;
    }
  }
}
