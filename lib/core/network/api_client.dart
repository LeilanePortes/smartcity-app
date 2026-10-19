import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

/// Cliente HTTP fino sobre o Dio. Centraliza base URL, timeouts, log em debug
/// e a conversão de qualquer falha para [ApiException].
class ApiClient {
  ApiClient({Dio? dio}) : _dio = dio ?? _defaultDio();

  final Dio _dio;

  Dio get raw => _dio;

  static Dio _defaultDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.httpConnectTimeout,
        receiveTimeout: AppConfig.httpReceiveTimeout,
        headers: {'Accept': 'application/json'},
        responseType: ResponseType.json,
      ),
    );
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: false,
          requestHeader: false,
          responseHeader: false,
        ),
      );
    }
    return dio;
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    return _run<T>(
      () => _dio.get<T>(
        path,
        queryParameters: _clean(query),
        cancelToken: cancelToken,
      ),
    );
  }

  Future<T> post<T>(
    String path, {
    Object? body,
    CancelToken? cancelToken,
  }) async {
    return _run<T>(
      () => _dio.post<T>(path, data: body, cancelToken: cancelToken),
    );
  }

  Future<T> patch<T>(
    String path, {
    Object? body,
    CancelToken? cancelToken,
  }) async {
    return _run<T>(
      () => _dio.patch<T>(path, data: body, cancelToken: cancelToken),
    );
  }

  Future<T> _run<T>(Future<Response<T>> Function() call) async {
    try {
      final res = await call();
      return res.data as T;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Remove chaves nulas/vazias para não mandar `?status=` à toa.
  Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    final out = <String, dynamic>{};
    query.forEach((k, v) {
      if (v == null) return;
      if (v is String && v.trim().isEmpty) return;
      out[k] = v;
    });
    return out.isEmpty ? null : out;
  }
}
