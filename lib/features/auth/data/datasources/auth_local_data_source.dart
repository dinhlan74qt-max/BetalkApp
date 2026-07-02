import 'package:socialnetwork/data/models/userModel.dart';
import 'package:socialnetwork/data/repositories/prefs/UserPrefsService.dart';

abstract class AuthLocalDataSource {
  Future<void> saveUser(UserModel user);

  Future<UserModel?> getUser();

  Future<void> clearUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  @override
  Future<void> saveUser(UserModel user) {
    return UserPrefsService.saveUser(user);
  }

  @override
  Future<UserModel?> getUser() {
    return UserPrefsService.getUser();
  }

  @override
  Future<void> clearUser() {
    return UserPrefsService.clear();
  }
}
