import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_params.freezed.dart';

/// Domain Params for login.
///
/// Per DOMAIN_LAYER.md, a Params class is normally only created when ≥4
/// fields. Login has 2 fields, but we use a class here to demonstrate the
/// Params → Request mapper pattern in the scaffold.
@freezed
abstract class LoginParams with _$LoginParams {
  const factory LoginParams({
    @Default('') String email,
    @Default('') String password,
  }) = _LoginParams;
}
