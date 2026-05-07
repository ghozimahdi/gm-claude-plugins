import 'package:freezed_annotation/freezed_annotation.dart';

part 'register_params.freezed.dart';

/// Domain Params for the register action.
///
/// Per DOMAIN_LAYER.md: a Params class is mandatory once a method has ≥4
/// parameters. Register has 5 (name, email, password, mobile,
/// hasAgreedToPDPA), so Params wraps them as a single typed value.
@freezed
abstract class RegisterParams with _$RegisterParams {
  const factory RegisterParams({
    @Default('') String name,
    @Default('') String email,
    @Default('') String password,
    @Default('') String mobile,
    @Default(false) bool hasAgreedToPDPA,
  }) = _RegisterParams;
}
