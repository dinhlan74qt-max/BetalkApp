import '../data/datasources/auth_local_data_source.dart';
import '../data/datasources/auth_remote_data_source.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/usecases/check_email_usecase.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/register_usecase.dart';
import '../domain/usecases/update_fcm_token_usecase.dart';

class AuthDependencies {
  AuthDependencies._();

  static final AuthRepositoryImpl _repository = AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(),
    localDataSource: AuthLocalDataSourceImpl(),
  );

  static final CheckEmailUseCase checkEmail = CheckEmailUseCase(_repository);
  static final LoginUseCase login = LoginUseCase(_repository);
  static final RegisterUseCase register = RegisterUseCase(_repository);
  static final UpdateFcmTokenUseCase updateFcmToken =
      UpdateFcmTokenUseCase(_repository);
}
