import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:socialnetwork/data/models/userModel.dart';
import 'package:socialnetwork/data/repositories/services/FcmService.dart';
import 'package:socialnetwork/data/server/ServerConfig.dart';
import 'package:socialnetwork/features/auth/domain/entities/auth_login_result.dart';
import 'package:socialnetwork/features/auth/domain/entities/auth_register_result.dart';
import 'package:socialnetwork/features/auth/domain/entities/check_email_result.dart';

abstract class AuthRemoteDataSource {
  Future<CheckEmailResult> checkEmail(String email);

  Future<AuthLoginResult> login(String email, String password);

  Future<AuthRegisterResult> register(Map<String, dynamic> data);

  Future<void> updateFcmToken(String userId, String token);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<CheckEmailResult> checkEmail(String email) async {
    final url = Uri.parse('${ServerConfig.baseUrl}/users/register/checkEmail');

    try {
      final response = await http.post(
        url,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final isAvailable = data['status'] == false || data['status'] == 'false';
        return CheckEmailResult(
          isAvailable: isAvailable,
          message: isAvailable
              ? 'Email chưa được đăng ký'
              : 'Email đã được đăng ký',
        );
      }

      return const CheckEmailResult(
        isAvailable: false,
        message: 'Lỗi hệ thống',
      );
    } catch (_) {
      return const CheckEmailResult(
        isAvailable: false,
        message: 'Lỗi hệ thống',
      );
    }
  }

  @override
  Future<AuthLoginResult> login(String email, String password) async {
    final url = Uri.parse('${ServerConfig.baseUrl}/users/login');

    try {
      final token = await FcmService.getCurrentToken();
      final response = await http.post(
        url,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'fcmToken': token,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final success = data['success'] == true;

      return AuthLoginResult(
        success: success,
        message: data['message']?.toString() ?? (success ? 'Đăng nhập thành công' : 'Đăng nhập thất bại'),
        error: data['error']?.toString(),
        user: data['user'] is Map<String, dynamic>
            ? UserModel.fromJson(data['user'] as Map<String, dynamic>)
            : null,
        token: data['token']?.toString(),
      );
    } catch (e) {
      return AuthLoginResult(
        success: false,
        message: 'Đăng nhập thất bại',
        error: e.toString(),
      );
    }
  }

  @override
  Future<AuthRegisterResult> register(Map<String, dynamic> data) async {
    final url = Uri.parse('${ServerConfig.baseUrl}/users/register');

    try {
      final response = await http.post(
        url,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      final body = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;

      if (response.statusCode == 200) {
        return AuthRegisterResult(
          success: true,
          message: 'Đăng ký thành công',
          data: body,
        );
      }

      return AuthRegisterResult(
        success: false,
        message: 'Server error ${response.statusCode}',
        data: body,
      );
    } catch (e) {
      return AuthRegisterResult(
        success: false,
        message: 'Lỗi hệ thống',
        error: e.toString(),
      );
    }
  }

  @override
  Future<void> updateFcmToken(String userId, String token) async {
    final url = Uri.parse('${ServerConfig.baseUrl}/users/updateToken');

    try {
      await http.post(
        url,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': userId,
          'token': token,
        }),
      );
    } catch (_) {
      // Keep silent here so token refresh does not break app flow.
    }
  }
}
