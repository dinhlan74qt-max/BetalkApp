import 'package:socialnetwork/data/models/userModel.dart';

class AuthLoginResult {
  final bool success;
  final String message;
  final String? error;
  final UserModel? user;
  final String? token;

  const AuthLoginResult({
    required this.success,
    required this.message,
    this.error,
    this.user,
    this.token,
  });
}
