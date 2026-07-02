import 'package:socialnetwork/data/models/userModel.dart';

import '../../domain/entities/auth_login_result.dart';
import '../../domain/entities/auth_register_result.dart';
import '../../domain/entities/check_email_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<CheckEmailResult> checkEmail(String email) {
    return remoteDataSource.checkEmail(email);
  }

  @override
  Future<AuthLoginResult> login(String email, String password) async {
    final result = await remoteDataSource.login(email, password);

    if (result.success && result.user != null) {
      await localDataSource.saveUser(result.user!);
    }

    return result;
  }

  @override
  Future<AuthRegisterResult> register(Map<String, dynamic> data) {
    return remoteDataSource.register(data);
  }

  @override
  Future<void> updateFcmToken(String userId, String token) {
    return remoteDataSource.updateFcmToken(userId, token);
  }

  Future<UserModel?> getCachedUser() {
    return localDataSource.getUser();
  }

  Future<void> clearCachedUser() {
    return localDataSource.clearUser();
  }
}
