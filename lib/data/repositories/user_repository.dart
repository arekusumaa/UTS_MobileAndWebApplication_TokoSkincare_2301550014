import '../models/app_user.dart';

abstract class UserRepository {
  AppUser? login(String email, String password);
  void register(AppUser user, String password);
  AppUser? getUserByEmail(String email);
}
