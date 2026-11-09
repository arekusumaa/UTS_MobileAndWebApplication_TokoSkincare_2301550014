import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/validasi_auth.dart';
import '../data/models/app_user.dart';
import '../data/repositories/user_repository.dart';

/// Email admin versi Minggu 9. Sejak Minggu 10 peran dibaca dari dokumen
/// `users/{uid}` di Firestore, jadi konstanta ini **hanya** dipakai bila
/// provider dibuat tanpa `UserRepository` (mode mock / widget test lama).
/// Jalur produksi di `main.dart` selalu menyuntikkan repository Firestore.
const String kAdminEmail = 'admin@skincare.id';

/// Status autentikasi aplikasi.
///
/// Autentikasi tetap bersumber dari Firebase Authentication, sedangkan
/// otorisasi (`role`) bersumber dari dokumen `users/{uid}` di Firestore.
/// Provider ini mendengarkan [FirebaseAuth.authStateChanges] dan `DataSync`
/// supaya peran admin yang diubah di Console langsung berlaku tanpa login
/// ulang.
class AuthProvider extends ChangeNotifier {
  AuthProvider({UserRepository? userRepository, Listenable? sync})
      : _userRepository = userRepository,
        _sync = sync {
    // Isi sinkron lebih dulu agar halaman yang langsung memakai currentUser
    // tidak sempat melihat null pada frame pertama.
    _currentUser = _dariFirebase(_auth.currentUser);
    _subscription = _auth.authStateChanges().listen((user) {
      _currentUser = _dariFirebase(user);
      _errorMessage = null;
      _notify();
    });
    _sync?.addListener(_onDataBerubah);
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository? _userRepository;
  final Listenable? _sync;
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

  /// Dokumen `users/{uid}` datang belakangan (asinkron). Saat listener
  /// Firestore memberi tahu ada perubahan, hitung ulang peran pengguna.
  void _onDataBerubah() {
    final user = _auth.currentUser;
    if (user == null) return;
    final baru = _dariFirebase(user, fallbackNama: _currentUser?.nama);
    if (baru == null) return;
    final lama = _currentUser;
    if (lama == null || lama.id != baru.id || lama.role != baru.role) {
      _currentUser = baru;
      _notify();
    }
  }

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

  /// Mendaftar akun baru. Nama disimpan sebagai displayName Firebase;
  /// dokumen `users/{uid}` dibuat otomatis oleh FirestoreDataSource dengan
  /// role 'pelanggan' (Security Rules menolak role lain saat create).
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

    final String role;
    if (_userRepository != null) {
      // Sumber kebenaran otorisasi = Firestore, BUKAN email hard-code.
      role = _userRepository.isAdmin(user.uid) ? 'admin' : 'pelanggan';
    } else {
      role = email.toLowerCase().trim() == kAdminEmail
          ? 'admin'
          : 'pelanggan';
    }

    return AppUser(
      id: user.uid,
      nama: nama,
      email: email,
      role: role,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _sync?.removeListener(_onDataBerubah);
    _subscription.cancel();
    super.dispose();
  }
}
