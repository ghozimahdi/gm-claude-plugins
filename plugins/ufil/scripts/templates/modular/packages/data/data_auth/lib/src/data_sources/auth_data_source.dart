import 'package:data_auth/src/models/create_new_account_request.dart';
import 'package:data_auth/src/models/login_request.dart';
import 'package:data_auth/src/models/login_response.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthDataSource {
  AuthDataSource(this._dio);

  final Dio _dio;

  /// Query — returns full Response. The OutputMapper turns it into Output.
  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/login',
      data: request.toJson(),
    );
    return LoginResponse.fromJson(response.data ?? const <String, dynamic>{});
  }

  /// Action — accepts a typed Request built by [CreateNewAccountRequestMapper].
  /// No return value: the repo returns `Failure.noFailure()` on success.
  Future<void> createNewAccount(CreateNewAccountRequest request) async {
    await _dio.post<void>('/v1/register', data: FormData.fromMap(request.toJson()));
  }
}
