import '../models/skin_profile.dart';
import '../repositories/skin_profile_repository.dart';

class MockSkinProfileSource implements SkinProfileRepository {
  final Map<String, SkinProfile> _profiles = {};

  @override
  SkinProfile getProfile(String userId) {
    return _profiles[userId] ?? SkinProfile.empty();
  }

  @override
  void saveProfile(String userId, SkinProfile profile) {
    _profiles[userId] = profile;
  }
}
