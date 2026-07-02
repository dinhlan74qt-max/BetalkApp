import '../repositories/auth_repository.dart';

class UpdateFcmTokenUseCase {
  final AuthRepository repository;

  const UpdateFcmTokenUseCase(this.repository);

  Future<void> call({
    required String userId,
    required String token,
  }) {
    return repository.updateFcmToken(userId, token);
  }
}
