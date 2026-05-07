import 'package:domain_auth/src/models/register_params.dart';
import 'package:domain_auth/src/repositories/auth_repository.dart';
import 'package:domain_common/domain_common.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class RegisterUseCase {
  RegisterUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<Failure> call(RegisterParams params) {
    return _authRepository.register(params);
  }
}
