import '../entities/auth_login_result.dart';
import '../entities/auth_register_result.dart';
import '../entities/check_email_result.dart';

abstract class AuthRepository {
  Future<CheckEmailResult> checkEmail(String email);

  Future<AuthLoginResult> login(String email, String password);

  Future<AuthRegisterResult> register(Map<String, dynamic> data);

  Future<void> updateFcmToken(String userId, String token);
}
