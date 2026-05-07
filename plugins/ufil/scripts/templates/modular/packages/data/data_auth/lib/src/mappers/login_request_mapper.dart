import 'package:data_auth/src/models/login_request.dart';
import 'package:domain_auth/domain_auth.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class LoginRequestMapper {
  LoginRequest mapFromDomain(LoginParams params) {
    return LoginRequest(email: params.email, password: params.password);
  }
}
