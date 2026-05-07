import 'package:domain_auth/src/models/login_params.dart';
import 'package:domain_auth/src/models/login_result.dart';
import 'package:domain_auth/src/repositories/auth_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class LoginUseCase {
  LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<LoginResult> call(LoginParams params) {
    return _repository.login(params);
  }
}
