import 'package:data_auth/src/mappers/user_model_mapper.dart';
import 'package:data_auth/src/models/login_response.dart';
import 'package:domain_auth/domain_auth.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class LoginResultMapper {
  LoginResultMapper(this._userModelMapper);

  final UserModelMapper _userModelMapper;

  LoginResult mapFromData(LoginResponse? data) {
    return LoginResult(
      token: data?.token ?? '',
      user: _userModelMapper.mapFromData(data?.user),
    );
  }
}
