import 'package:domain_auth/domain_auth.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class GetIsLoginUseCase {
  final AuthRepository _repository;

  GetIsLoginUseCase(this._repository);

  bool call() {
    return _repository.getIsLogin();
  }
}
