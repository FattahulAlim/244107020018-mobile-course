import 'package:dio/dio.dart';
import '../features/auth/data/auth_repository.dart';
import 'token_store.dart';

Dio buildApiClient(TokenStore store, AuthRepository auth) {
  final dio = Dio(BaseOptions(
    baseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://example-campus-api.test',
    ),
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'Accept-Encoding': 'gzip, deflate',
    },
  ));

  // 1. In-memory cache interceptor untuk GET requests (mengurangi redundant round-trip)
  final cache = <String, Response>{};

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      if (options.method.toUpperCase() == 'GET' &&
          options.extra['no-cache'] != true) {
        final cacheKey = options.uri.toString();
        final cached = cache[cacheKey];
        if (cached != null) {
          return handler.resolve(
            Response(
              requestOptions: options,
              data: cached.data,
              statusCode: cached.statusCode,
              headers: cached.headers,
            ),
          );
        }
      }
      handler.next(options);
    },
    onResponse: (response, handler) {
      if (response.requestOptions.method.toUpperCase() == 'GET') {
        final cacheKey = response.requestOptions.uri.toString();
        cache[cacheKey] = response;
      }
      handler.next(response);
    },
  ));

  // 2. Auth Interceptor & Token Refresh
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final access = await store.readAccess();
      if (access != null) {
        options.headers['Authorization'] = 'Bearer $access';
      }
      handler.next(options);
    },
    onError: (e, handler) async {
      if (e.response?.statusCode == 401) {
        final refresh = await store.readRefresh();
        if (refresh == null) return handler.next(e);
        try {
          final renewed = await auth.refresh(refresh);
          await store.save(access: renewed, refresh: refresh);
          final retry = await dio.fetch(
            e.requestOptions..headers['Authorization'] = 'Bearer $renewed',
          );
          return handler.resolve(retry);
        } catch (_) {
          await store.clear(); // refresh ikut mati -> paksa login ulang
        }
      }
      handler.next(e);
    },
  ));

  return dio;
}