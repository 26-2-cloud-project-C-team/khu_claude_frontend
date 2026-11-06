import 'dart:async';

import 'package:dio/dio.dart';

import '../errors/app_exception.dart';

/// `/api/…`를 호출하는 HTTP 클라이언트다.
///
/// 성공하면 JSON을 디코딩한 값(본문이 없으면 `null`)을 돌려주고, 실패하면 [AppException]을 던진다.
class ApiClient {
  /// 운영과 로컬 개발 모두 웹과 API가 같은 origin이므로 [baseUrl]은 비워 두고 상대 경로로 호출한다.
  /// 세션 쿠키가 HttpOnly라 다른 origin을 호출하면 쿠키가 붙지 않는다.
  ApiClient({String baseUrl = '', HttpClientAdapter? adapter})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {'API-Version': '1'},
          responseType: ResponseType.json,
        ),
      ) {
    if (adapter != null) _dio.httpClientAdapter = adapter;
  }

  final Dio _dio;
  final _adminUnauthorized = StreamController<void>.broadcast();

  /// 관리자 API(`/api/admin/…`)가 `401`을 돌려줄 때마다 이벤트가 온다. 로그인 요청은 제외한다.
  Stream<void> get adminUnauthorized => _adminUnauthorized.stream;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? body}) =>
      _send(() => _dio.post(path, data: body));

  Future<dynamic> put(String path, {Object? body}) =>
      _send(() => _dio.put(path, data: body));

  Future<dynamic> patch(String path, {Object? body}) =>
      _send(() => _dio.patch(path, data: body));

  Future<dynamic> delete(String path, {Object? body}) =>
      _send(() => _dio.delete(path, data: body));

  void dispose() {
    _dio.close();
    _adminUnauthorized.close();
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      final data = response.data;
      return data == '' ? null : data;
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) throw const AppException();

      final statusCode = response.statusCode!;
      final path = e.requestOptions.uri.path;
      // 로그인 요청의 401은 Google 토큰 오류(AUTH_INVALID_GOOGLE_TOKEN)라 세션 만료 알림 대상이 아니다.
      if (statusCode == 401 &&
          path.startsWith('/api/admin/') &&
          path != '/api/admin/auth/google') {
        _adminUnauthorized.add(null);
      }
      throw _toException(statusCode, response);
    }
  }
}

AppException _toException(int statusCode, Response<dynamic> response) {
  final retryAfter = _parseRetryAfter(response.headers.value('retry-after'));
  // 5xx는 본문과 상관없이 상태 코드로 처리한다. 502·504는 프록시가 만든 HTML일 수도 있다.
  if (statusCode >= 500) {
    return AppException(statusCode: statusCode, retryAfter: retryAfter);
  }

  final error = switch (response.data) {
    {'error': final Map<String, dynamic> error} => error,
    _ => null,
  };
  return AppException(
    statusCode: statusCode,
    code: error?['code'] as String?,
    fieldErrors: _parseFieldErrors(error?['details']),
    retryAfter: retryAfter,
  );
}

List<FieldError> _parseFieldErrors(Object? details) {
  if (details case {'fields': final List<dynamic> fields}) {
    return [
      for (final field in fields)
        if (field case {
          'field': final String name,
          'reason': final String reason,
        })
          FieldError(field: name, reason: reason),
    ];
  }
  return const [];
}

Duration? _parseRetryAfter(String? value) {
  final seconds = int.tryParse(value?.trim() ?? '');
  return seconds == null ? null : Duration(seconds: seconds);
}
