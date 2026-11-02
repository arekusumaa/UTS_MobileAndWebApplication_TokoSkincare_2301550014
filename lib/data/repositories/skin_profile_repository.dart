import '../models/skin_profile.dart';

abstract class SkinProfileRepository {
  SkinProfile getProfile(String userId);
  void saveProfile(String userId, SkinProfile profile);
}
