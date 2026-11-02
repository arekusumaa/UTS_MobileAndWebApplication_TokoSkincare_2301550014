import 'package:flutter/material.dart';
import '../data/models/skin_profile.dart';
import '../data/data_sources/mock_skin_profile_source.dart';

class SkinProfileProvider extends ChangeNotifier {
  final MockSkinProfileSource _source = MockSkinProfileSource();
  SkinProfile _profile = SkinProfile.empty();

  SkinProfile get profile => _profile;
  bool get hasProfile => !_profile.isEmpty;

  void loadProfile(String userId) {
    _profile = _source.getProfile(userId);
    notifyListeners();
  }

  void saveProfile(String userId, SkinProfile profile) {
    _source.saveProfile(userId, profile);
    _profile = profile;
    notifyListeners();
  }
}
