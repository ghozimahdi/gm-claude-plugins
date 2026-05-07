import 'package:domain_common/domain_common.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_model.dart';

part 'login_result.freezed.dart';

/// Result for login.
///
/// Modular Results carry `@Default(Failure.noFailure()) Failure failure` so
/// the bloc can `switch (result.failure)` after the use case returns. On
/// failure, the data fields keep their defaults; on success, they are
/// populated by the ResultMapper.
@freezed
abstract class LoginResult with _$LoginResult {
  const factory LoginResult({
    @Default('') String token,
    @Default(UserModel()) UserModel user,
    @Default(Failure.noFailure()) Failure failure,
  }) = _LoginResult;
}
