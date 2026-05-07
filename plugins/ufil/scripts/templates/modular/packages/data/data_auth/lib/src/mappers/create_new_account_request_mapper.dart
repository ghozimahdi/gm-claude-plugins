import 'package:data_auth/src/models/create_new_account_request.dart';
import 'package:domain_auth/domain_auth.dart';
import 'package:injectable/injectable.dart';

/// Maps [RegisterParams] → [CreateNewAccountRequest].
///
/// The wire-level `action` constant lives here, NOT in the use case or repo.
@lazySingleton
class CreateNewAccountRequestMapper {
  CreateNewAccountRequest mapFromDomain(RegisterParams params) {
    return CreateNewAccountRequest(
      action: 'createNewAccount',
      name: params.name,
      email: params.email,
      password: params.password,
      mobile: params.mobile,
      hasAgreedToPDPA: params.hasAgreedToPDPA,
    );
  }
}
