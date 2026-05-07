import 'package:data_common/src/network/app_exception.dart';
import 'package:dio/dio.dart';
import 'package:domain_common/domain_common.dart';

mixin FailureHandlerMixin {
  Failure mapToFailure(Object error) {
    if (error is AppException) {
      return _mapAppExceptionToFailure(error);
    } else if (error is DioException) {
      return _mapDioExceptionToFailure(error);
    } else {
      return Failure.unexpectedError(message: error.toString());
    }
  }

  Failure _mapAppExceptionToFailure(AppException exception) {
    final message = exception.message ?? exception.toString();
    if (exception is UnauthorizedException) {
      return const Failure.unauthorized();
    } else if (exception is ServerException) {
      return const Failure.serverFailure();
    } else if (exception is ClientException) {
      return const Failure.requestFailure();
    } else if (exception is TimeoutException) {
      return const Failure.timeout();
    } else if (exception is NoConnectionException) {
      return const Failure.noConnection();
    }

    return Failure.unexpectedError(message: message);
  }

  Failure _mapDioExceptionToFailure(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const Failure.timeout();
      case DioExceptionType.connectionError:
        return const Failure.noConnection();
      default:
        return Failure.unexpectedError(
          message: exception.message ?? 'Unknown Dio error',
        );
    }
  }
}
