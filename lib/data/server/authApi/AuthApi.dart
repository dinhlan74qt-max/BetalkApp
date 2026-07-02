import 'package:socialnetwork/features/auth/di/auth_dependencies.dart';

class AuthApi {
  static Future<Map<String, dynamic>> checkEmail(String email) async {
    final result = await AuthDependencies.checkEmail(email);
    return {
      'status': result.isAvailable
          ? 'Email chưa được đăng ký'
          : 'Email đã được đăng ký',
    };
  }

  static Future<void> updateFcmToken(String id, String token) async {
    await AuthDependencies.updateFcmToken(
      userId: id,
      token: token,
    );
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await AuthDependencies.login(
      email: email,
      password: password,
    );

    return {
      'success': result.success,
      'message': result.message,
      'error': result.error,
      'user': result.user?.toJson(),
      'token': result.token,
    };
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final result = await AuthDependencies.register(data);

    return {
      'success': result.success,
      'message': result.message,
      'newData': result.data,
      'error': result.error,
    };
  }
}
