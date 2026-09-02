// core/network/api_client.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'token_storage.dart';

part 'api_client.g.dart';

/// Base URL — change to your Render URL in production.
const apiBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'https://staynest-bvyf.onrender.com/api/v1');

/// For iOS simulator talking to macOS localhost, use:
/// const _baseUrl = 'http://127.0.0.1:3000/api/v1';
///
/// For Android emulator:
/// const _baseUrl = 'http://10.0.2.2:3000/api/v1';

@riverpod
Dio dio(Ref ref) {
  final dio = Dio(BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  final tokenStorage = ref.read(tokenStorageProvider);

  // ── Auth interceptor ──────────────────────────────
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await tokenStorage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        // Try refresh
        final refreshToken = await tokenStorage.getRefreshToken();
        if (refreshToken != null) {
          try {
            final refreshDio = Dio(BaseOptions(baseUrl: apiBaseUrl));
            final res = await refreshDio.post(
              '/auth/refresh',
              options: Options(headers: {
                'Authorization': 'Bearer $refreshToken',
              }),
            );

            // Handle both {accessToken} and {tokens: {accessToken}} formats
            final data = res.data;
            final tokens = data['tokens'] as Map<String, dynamic>? ?? data;
            final newAccess = tokens['accessToken'] as String;
            final newRefresh = tokens['refreshToken'] as String;
            await tokenStorage.saveTokens(newAccess, newRefresh);

            // Retry original request
            error.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
            final retry = await dio.fetch(error.requestOptions);
            return handler.resolve(retry);
          } catch (_) {
            await tokenStorage.clear();
            return handler.next(error);
          }
        }
      }
      return handler.next(error);
    },
  ));

  return dio;
}
