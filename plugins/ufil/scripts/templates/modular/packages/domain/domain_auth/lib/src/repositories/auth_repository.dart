import 'package:domain_auth/src/models/login_params.dart';
import 'package:domain_auth/src/models/login_result.dart';
import 'package:domain_auth/src/models/register_params.dart';
import 'package:domain_common/domain_common.dart';

abstract class AuthRepository {
  /// Query (returns data) → returns `Future<Result>`. Result carries `Failure`
  /// + payload so the bloc can `switch (result.failure)`.
  Future<LoginResult> login(LoginParams params);

  /// Action (no data) → returns `Future<Failure>` directly. `Failure.noFailure()`
  /// signals success.
  Future<Failure> logout();

  /// Action (no data) → returns `Future<Failure>` directly. Takes typed
  /// [RegisterParams]; the data layer maps it to the wire request via
  /// `CreateNewAccountRequestMapper`.
  Future<Failure> register(RegisterParams params);

  /// Synchronous query against local cache. Pure data, no failure path needed.
  bool getIsLogin();
}
