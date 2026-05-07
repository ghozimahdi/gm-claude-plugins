import 'package:dio/dio.dart';

class AppException extends DioException {
  final int? statusCode;

  AppException({required String message, this.statusCode})
    : super(requestOptions: RequestOptions(), message: message);

  @override
  String toString() {
    return 'AppException: $error (statusCode: $statusCode)';
  }
}

class UnauthorizedException extends AppException {
  UnauthorizedException()
    : super(message: 'Unauthorized access', statusCode: 401);
}

class NoConnectionException extends AppException {
  NoConnectionException() : super(message: 'No internet connection');
}

class TimeoutException extends AppException {
  TimeoutException() : super(message: 'Request timed out');
}

class ForbiddenException extends AppException {
  ForbiddenException() : super(message: 'Access forbidden', statusCode: 403);
}

class ServerException extends AppException {
  ServerException() : super(message: 'Internal server error', statusCode: 500);
}

class ClientException extends AppException {
  ClientException({required super.message, super.statusCode}) : super();
}
