import '../entities/auth_register_result.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  const RegisterUseCase(this.repository);

  Future<AuthRegisterResult> call(Map<String, dynamic> data) {
    return repository.register(data);
  }
}
