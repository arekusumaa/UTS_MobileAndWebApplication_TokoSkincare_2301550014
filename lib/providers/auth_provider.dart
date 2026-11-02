import 'package:flutter/material.dart';
import '../data/models/app_user.dart';
import '../data/data_sources/mock_user_source.dart';

class AuthProvider extends ChangeNotifier {
  final MockUserSource _userSource = MockUserSource();

  AppUser? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;

  AppUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  bool login(String email, String password) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final user = _userSource.login(email, password);
    _isLoading = false;

    if (user != null) {
      _currentUser = user;
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Email atau kata sandi salah';
      notifyListeners();
      return false;
    }
  }

  bool register(String nama, String email, String password) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = AppUser(
        id: 'U${DateTime.now().millisecondsSinceEpoch}',
        nama: nama,
        email: email,
        role: 'pelanggan',
      );
      _userSource.register(user, password);
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
