import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_new_account_request.freezed.dart';
part 'create_new_account_request.g.dart';

/// Outgoing request body for POST /v1/register.
///
/// `action` is fixed to `'createNewAccount'` at the mapper boundary so the
/// domain layer never has to know about wire-level constants.
@freezed
abstract class CreateNewAccountRequest with _$CreateNewAccountRequest {
  const factory CreateNewAccountRequest({
    @JsonKey(name: 'action') required String action,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'email') required String email,
    @JsonKey(name: 'password') required String password,
    @JsonKey(name: 'mobile') required String mobile,
    @JsonKey(name: 'hasAgreedToPDPA') required bool hasAgreedToPDPA,
  }) = _CreateNewAccountRequest;

  factory CreateNewAccountRequest.fromJson(Map<String, dynamic> json) {
    return _$CreateNewAccountRequestFromJson(json);
  }
}
