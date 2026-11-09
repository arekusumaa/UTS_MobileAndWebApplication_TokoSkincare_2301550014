import 'package:flutter/material.dart';
import '../data/models/skin_profile.dart';
import '../data/data_sources/mock_skin_profile_source.dart';
import '../data/repositories/skin_profile_repository.dart';

class SkinProfileProvider extends ChangeNotifier {
  SkinProfileProvider({SkinProfileRepository? source, Listenable? sync})
      : _source = source ?? MockSkinProfileSource(),
        _sync = sync {
    _sync?.addListener(_onDataBerubah);
  }

  final SkinProfileRepository _source;
  final Listenable? _sync;
  SkinProfile _profile = SkinProfile.empty();
  String? _userIdTerakhir;

  SkinProfile get profile => _profile;
  bool get hasProfile => !_profile.isEmpty;

  void loadProfile(String userId) {
    _userIdTerakhir = userId;
    _profile = _source.getProfile(userId);
    notifyListeners();
  }

  /// Menjaga halaman Profil Kulit tetap sinkron bila dokumen diubah dari
  /// perangkat lain. Tidak menimpa data saat pengguna belum memuat profil.
  void _onDataBerubah() {
    final uid = _userIdTerakhir;
    if (uid == null || uid.isEmpty) return;
    _profile = _source.getProfile(uid);
    notifyListeners();
  }

  void saveProfile(String userId, SkinProfile profile) {
    _userIdTerakhir = userId;
    _source.saveProfile(userId, profile);
    _profile = profile;
    notifyListeners();
  }

  @override
  void dispose() {
    _sync?.removeListener(_onDataBerubah);
    super.dispose();
  }
}
