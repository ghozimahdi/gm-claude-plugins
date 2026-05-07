import 'dart:convert';

import 'package:data_common/src/network/app_exception.dart';
import 'package:dio/dio.dart';

class DioErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    return _mapDioExceptionToAppException(err);
  }

  void _mapDioExceptionToAppException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw TimeoutException();

      case DioExceptionType.connectionError:
        throw NoConnectionException();

      case DioExceptionType.badResponse:
        final statusCode = exception.response?.statusCode ?? 0;
        final errorMessage =
            _extractErrorMessage(exception.response?.data) ??
            'An unknown error occurred';

        if (statusCode == 401) {
          throw UnauthorizedException();
        } else if (statusCode == 403) {
          throw ForbiddenException();
        } else if (statusCode >= 400 && statusCode < 500) {
          throw ClientException(message: errorMessage, statusCode: statusCode);
        } else if (statusCode >= 500) {
          throw ServerException();
        }

        throw AppException(message: errorMessage, statusCode: statusCode);

      case DioExceptionType.badCertificate:
        throw AppException(message: 'SSL certificate validation failed');

      case DioExceptionType.cancel:
        throw AppException(message: 'Request was cancelled');

      case DioExceptionType.unknown:
        throw AppException(
          message: exception.message ?? 'An unknown error occurred',
        );
    }
  }

  String? _extractErrorMessage(Object? data) {
    try {
      if (data is Map<String, dynamic>) {
        return data['message'] as String?;
      } else if (data is String) {
        final jsonData = jsonDecode(data) as Map<String, dynamic>;
        return jsonData['message'] as String?;
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
