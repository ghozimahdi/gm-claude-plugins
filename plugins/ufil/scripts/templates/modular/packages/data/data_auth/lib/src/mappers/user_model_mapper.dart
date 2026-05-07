import 'package:data_auth/src/models/user_dto.dart';
import 'package:domain_auth/domain_auth.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class UserModelMapper {
  UserModel mapFromData(UserDto? data) {
    return UserModel(
      id: data?.id ?? '',
      name: data?.name ?? '',
      email: data?.email ?? '',
    );
  }
}
