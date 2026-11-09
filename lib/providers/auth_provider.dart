import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/validasi_auth.dart';
import '../data/models/app_user.dart';

/// Email yang untuk sementara dipetakan sebagai admin.
///
/// Minggu 9 belum memakai Firestore, sehingga role belum bisa dibaca dari
/// database. Pemetaan ini akan digantikan dokumen `users/{uid}` pada Minggu 10.
const String kAdminEmail = 'admin@skincare.id';

/// Status autentikasi aplikasi.
///
/// Sumber kebenarannya adalah Firebase Authentication, bukan data simulasi.
/// Provider ini mendengarkan [FirebaseAuth.authStateChanges] supaya state
/// ikut berubah saat pengguna masuk, keluar, atau sesinya dipulihkan setelah
/// browser di-refresh.
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    // Isi sinkron lebih dulu agar halaman yang langsung memakai currentUser
    // tidak sempat melihat null pada frame pertama.
    _currentUser = _dariFirebase(_auth.currentUser);
    _subscription = _auth.authStateChanges().listen((user) {
      _currentUser = _dariFirebase(user);
      _errorMessage = null;
      _notify();
    });
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final StreamSubscription<User?> _subscription;
  bool _disposed = false;

  AppUser? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;

  AppUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Masuk dengan email dan password. Mengembalikan true bila berhasil.
  /// Halaman tidak perlu memanggil Navigator: CekStatusLogin dan redirect
  /// GoRouter akan mengganti halaman mengikuti status Firebase.
  Future<bool> login(String email, String password) async {
    _mulaiProses();
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _currentUser = _dariFirebase(_auth.currentUser);
      _selesaiProses();
      return true;
    } on FirebaseAuthException catch (e) {
      _gagal(pesanKesalahanAuth(e.code));
      return false;
    } catch (_) {
      _gagal('Terjadi kesalahan. Silakan coba lagi.');
      return false;
    }
  }

  /// Mendaftar akun baru. Nama disimpan sebagai displayName Firebase,
  /// sehingga bisa dipakai di halaman Akun tanpa perlu Firestore.
  Future<bool> register(String nama, String email, String password) async {
    _mulaiProses();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(nama.trim());
      _currentUser = _dariFirebase(
        _auth.currentUser,
        fallbackNama: nama.trim(),
      );
      _selesaiProses();
      return true;
    } on FirebaseAuthException catch (e) {
      _gagal(pesanKesalahanAuth(e.code));
      return false;
    } catch (_) {
      _gagal('Terjadi kesalahan. Silakan coba lagi.');
      return false;
    }
  }

  /// Keluar. Navigasi kembali ke halaman Masuk ditangani auth gate.
  Future<void> logout() async {
    _errorMessage = null;
    _isLoading = false;
    _currentUser = null;
    _notify();
    await _auth.signOut();
  }

  void clearError() {
    _errorMessage = null;
    _notify();
  }

  void _mulaiProses() {
    _isLoading = true;
    _errorMessage = null;
    _notify();
  }

  void _selesaiProses() {
    _isLoading = false;
    _notify();
  }

  void _gagal(String pesan) {
    _errorMessage = pesan;
    _isLoading = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  AppUser? _dariFirebase(User? user, {String? fallbackNama}) {
    if (user == null) return null;
    final email = user.email ?? '';
    final displayName = user.displayName?.trim() ?? '';
    final namaLokal = email.contains('@') ? email.split('@').first : 'Pengguna';
    final nama = (fallbackNama != null && fallbackNama.isNotEmpty)
        ? fallbackNama
        : (displayName.isNotEmpty ? displayName : namaLokal);

    return AppUser(
      id: user.uid,
      nama: nama,
      email: email,
      role: email.toLowerCase().trim() == kAdminEmail ? 'admin' : 'pelanggan',
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription.cancel();
    super.dispose();
  }
}
