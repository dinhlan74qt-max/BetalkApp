import '../entities/check_email_result.dart';
import '../repositories/auth_repository.dart';

class CheckEmailUseCase {
  final AuthRepository repository;

  const CheckEmailUseCase(this.repository);

  Future<CheckEmailResult> call(String email) {
    return repository.checkEmail(email);
  }
}
