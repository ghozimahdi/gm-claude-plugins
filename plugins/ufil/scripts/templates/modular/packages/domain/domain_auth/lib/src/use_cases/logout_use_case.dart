import 'package:domain_auth/src/repositories/auth_repository.dart';
import 'package:domain_common/domain_common.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class LogoutUseCase {
  LogoutUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<Failure> call() {
    return _authRepository.logout();
  }
}
