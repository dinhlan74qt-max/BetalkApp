class AuthRegisterResult {
  final bool success;
  final String message;
  final dynamic data;
  final String? error;

  const AuthRegisterResult({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });
}
