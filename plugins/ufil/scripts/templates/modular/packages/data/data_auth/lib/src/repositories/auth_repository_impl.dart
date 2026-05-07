import 'package:data_auth/src/data_sources/auth_data_source.dart';
import 'package:data_auth/src/mappers/create_new_account_request_mapper.dart';
import 'package:data_auth/src/mappers/login_request_mapper.dart';
import 'package:data_auth/src/mappers/login_result_mapper.dart';
import 'package:data_common/data_common.dart';
import 'package:domain_auth/domain_auth.dart';
import 'package:domain_common/domain_common.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl extends AuthRepository with FailureHandlerMixin {
  AuthRepositoryImpl(
    this._authDataSource,
    this._preferenceDataSource,
    this._loginRequestMapper,
    this._loginResultMapper,
    this._createNewAccountRequestMapper,
  );

  final AuthDataSource _authDataSource;
  final SharedPreferenceDataSource _preferenceDataSource;
  final LoginRequestMapper _loginRequestMapper;
  final LoginResultMapper _loginResultMapper;
  final CreateNewAccountRequestMapper _createNewAccountRequestMapper;

  /// Query → returns Result (carries Failure + payload).
  /// Pass the full Response to ResultMapper — never map field-by-field here.
  @override
  Future<LoginResult> login(LoginParams params) async {
    try {
      final request = _loginRequestMapper.mapFromDomain(params);
      final response = await _authDataSource.login(request);
      await _preferenceDataSource.setIsLogin(true);
      return _loginResultMapper.mapFromData(response);
    } catch (e) {
      return LoginResult(failure: mapToFailure(e));
    }
  }

  /// Action → returns Failure directly. Params is mapped to a typed Request
  /// via [CreateNewAccountRequestMapper]; the wire-level `action` constant
  /// lives in the mapper, not here.
  @override
  Future<Failure> register(RegisterParams params) async {
    try {
      final request = _createNewAccountRequestMapper.mapFromDomain(params);
      await _authDataSource.createNewAccount(request);
      return const Failure.noFailure();
    } catch (e) {
      return mapToFailure(e);
    }
  }

  /// Action → returns Failure directly.
  @override
  Future<Failure> logout() async {
    try {
      await _preferenceDataSource.clearAllData();
      return const Failure.noFailure();
    } catch (e) {
      return mapToFailure(e);
    }
  }

  @override
  bool getIsLogin() {
    return _preferenceDataSource.getIsLogin();
  }
}
