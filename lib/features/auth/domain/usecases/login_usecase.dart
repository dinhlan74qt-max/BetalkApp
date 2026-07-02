import '../entities/auth_login_result.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  const LoginUseCase(this.repository);

  Future<AuthLoginResult> call({
    required String email,
    required String password,
  }) {
    return repository.login(email, password);
  }
}
