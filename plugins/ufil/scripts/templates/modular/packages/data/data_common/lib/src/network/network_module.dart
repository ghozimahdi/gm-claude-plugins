import 'package:data_common/data_common.dart';
import 'package:data_common/src/network/dio_error_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:domain_common/domain_common.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@module
abstract class NetworkModule {
  @Singleton(env: [Environment.prod])
  Dio dioProd(DataSourceConfig config) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: const Duration(milliseconds: 20000),
        sendTimeout: const Duration(milliseconds: 30000),
        receiveTimeout: const Duration(milliseconds: 30000),
      ),
    );

    dio.interceptors.add(DioErrorInterceptor());

    if (kDebugMode) {
      dio.interceptors.addAll([
        LogInterceptor(requestBody: true, responseBody: true),
        ChuckerDioInterceptor(),
      ]);
    }
    return dio;
  }

  @Singleton(env: [Environment.dev, Environment.test])
  Dio dioDev(DataSourceConfig config) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: const Duration(milliseconds: 20000),
        sendTimeout: const Duration(milliseconds: 30000),
        receiveTimeout: const Duration(milliseconds: 30000),
      ),
    );

    dio.interceptors.addAll([
      LogInterceptor(requestBody: true, responseBody: true),
      ChuckerDioInterceptor(),
      DioErrorInterceptor(),
    ]);
    return dio;
  }
}
