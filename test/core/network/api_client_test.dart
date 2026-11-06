import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/errors/app_exception.dart';
import 'package:team_frontend/core/network/api_client.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;
  RequestOptions? lastRequest;
  String? lastBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    if (requestStream != null) {
      lastBody = utf8.decode(
        await requestStream.expand((chunk) => chunk).toList(),
      );
    }
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(
  int statusCode,
  Object? body, {
  Map<String, List<String>> headers = const {},
}) => ResponseBody.fromString(
  jsonEncode(body),
  statusCode,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
    ...headers,
  },
);

Future<AppException> _catchError(Future<dynamic> call) async {
  try {
    await call;
  } on AppException catch (e) {
    return e;
  }
  fail('AppException이 발생하지 않았다');
}

void main() {
  group('정상 응답', () {
    test('JSON 본문을 디코딩해 돌려준다', () async {
      final adapter = _FakeAdapter(
        (_) => _json(200, {'id': 3, 'name': '중앙도서관', 'memo': null}),
      );
      final client = ApiClient(adapter: adapter);

      final data = await client.get('/api/buildings', query: {'q': '도서관'});

      expect(data, {'id': 3, 'name': '중앙도서관', 'memo': null});
      expect(adapter.lastRequest!.uri.path, '/api/buildings');
      expect(adapter.lastRequest!.uri.queryParameters, {'q': '도서관'});
    });

    test('API-Version 헤더와 JSON 본문을 보낸다', () async {
      final adapter = _FakeAdapter((_) => _json(201, {'id': 1}));
      final client = ApiClient(adapter: adapter);

      await client.post('/api/reviews', body: {'rating': 5});

      final request = adapter.lastRequest!;
      expect(request.headers['API-Version'], '1');
      expect(request.contentType, startsWith(Headers.jsonContentType));
      expect(jsonDecode(adapter.lastBody!), {'rating': 5});
    });

    test('본문이 없는 응답은 null을 돌려준다', () async {
      final client = ApiClient(
        adapter: _FakeAdapter((_) => ResponseBody.fromString('', 204)),
      );

      expect(await client.delete('/api/admin/spaces/3'), isNull);
    });
  });

  group('에러 스키마 응답', () {
    test('error.code로 예외를 만든다', () async {
      final client = ApiClient(
        adapter: _FakeAdapter(
          (_) => _json(404, {
            'error': {
              'code': 'SPACE_NOT_FOUND',
              'message': '공간을 찾을 수 없습니다.',
              'details': null,
            },
          }),
        ),
      );

      final e = await _catchError(client.get('/api/spaces/3'));

      expect(e.statusCode, 404);
      expect(e.code, 'SPACE_NOT_FOUND');
      expect(e.message, '공간을 찾을 수 없습니다.');
      expect(e.fieldErrors, isEmpty);
      expect(e.isServerError, isFalse);
    });

    test('details.fields를 필드 오류로 옮긴다', () async {
      final client = ApiClient(
        adapter: _FakeAdapter(
          (_) => _json(400, {
            'error': {
              'code': 'COMMON_VALIDATION_FAILED',
              'message': '입력값이 올바르지 않습니다.',
              'details': {
                'fields': [
                  {'field': 'content', 'reason': 'TOO_LONG'},
                  {'field': 'rating', 'reason': 'OUT_OF_RANGE'},
                ],
              },
            },
          }),
        ),
      );

      final e = await _catchError(client.post('/api/reviews', body: {}));

      expect(e.code, 'COMMON_VALIDATION_FAILED');
      expect(e.fieldErrors, const [
        FieldError(field: 'content', reason: 'TOO_LONG'),
        FieldError(field: 'rating', reason: 'OUT_OF_RANGE'),
      ]);
    });

    test('에러 스키마가 아닌 4xx는 code 없이 상태 코드만 담는다', () async {
      final client = ApiClient(
        adapter: _FakeAdapter((_) => _json(400, {'unexpected': true})),
      );

      final e = await _catchError(client.get('/api/spaces'));

      expect(e.statusCode, 400);
      expect(e.code, isNull);
      expect(e.message, isNull);
    });
  });

  group('5xx', () {
    test('에러 스키마 본문이 있어도 code를 담지 않는다', () async {
      final client = ApiClient(
        adapter: _FakeAdapter(
          (_) => _json(500, {
            'error': {
              'code': 'COMMON_INTERNAL_ERROR',
              'message': '서버 오류',
              'details': null,
            },
          }),
        ),
      );

      final e = await _catchError(client.get('/api/spaces'));

      expect(e.statusCode, 500);
      expect(e.code, isNull);
      expect(e.message, isNull);
      expect(e.isServerError, isTrue);
    });

    test('HTML 본문인 502도 상태 코드로 처리한다', () async {
      final client = ApiClient(
        adapter: _FakeAdapter(
          (_) => ResponseBody.fromString(
            '<html><body>502 Bad Gateway</body></html>',
            502,
            headers: {
              Headers.contentTypeHeader: ['text/html'],
            },
          ),
        ),
      );

      final e = await _catchError(client.get('/api/spaces'));

      expect(e.statusCode, 502);
      expect(e.code, isNull);
      expect(e.isServerError, isTrue);
    });
  });

  group('Retry-After', () {
    test('429의 초 단위 값을 담는다', () async {
      final client = ApiClient(
        adapter: _FakeAdapter(
          (_) => _json(
            429,
            {
              'error': {
                'code': 'COMMON_RATE_LIMITED',
                'message': '요청이 너무 많습니다.',
                'details': null,
              },
            },
            headers: {
              'retry-after': ['30'],
            },
          ),
        ),
      );

      final e = await _catchError(client.post('/api/reviews', body: {}));

      expect(e.code, 'COMMON_RATE_LIMITED');
      expect(e.retryAfter, const Duration(seconds: 30));
    });

    test('503의 값을 담는다', () async {
      final client = ApiClient(
        adapter: _FakeAdapter(
          (_) => ResponseBody.fromString(
            '',
            503,
            headers: {
              'retry-after': ['120'],
            },
          ),
        ),
      );

      final e = await _catchError(client.get('/api/spaces'));

      expect(e.statusCode, 503);
      expect(e.retryAfter, const Duration(seconds: 120));
    });

    test('헤더가 없으면 null이다', () async {
      final client = ApiClient(adapter: _FakeAdapter((_) => _json(429, {})));

      final e = await _catchError(client.get('/api/spaces'));

      expect(e.retryAfter, isNull);
    });
  });

  test('응답을 받지 못하면 네트워크 오류다', () async {
    final client = ApiClient(
      adapter: _FakeAdapter(
        (options) => throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
        ),
      ),
    );

    final e = await _catchError(client.get('/api/spaces'));

    expect(e.isNetworkError, isTrue);
    expect(e.statusCode, isNull);
  });

  group('관리자 401 알림', () {
    ResponseBody unauthorized(RequestOptions _) => _json(401, {
      'error': {
        'code': 'AUTH_UNAUTHORIZED',
        'message': '로그인이 필요합니다.',
        'details': null,
      },
    });

    test('관리자 API의 401이면 이벤트를 보낸다', () async {
      final client = ApiClient(adapter: _FakeAdapter(unauthorized));
      var count = 0;
      client.adminUnauthorized.listen((_) => count++);

      await _catchError(client.get('/api/admin/spaces'));
      await Future<void>.delayed(Duration.zero);

      expect(count, 1);
    });

    test('사용자 API의 401은 이벤트를 보내지 않는다', () async {
      final client = ApiClient(adapter: _FakeAdapter(unauthorized));
      var count = 0;
      client.adminUnauthorized.listen((_) => count++);

      await _catchError(client.get('/api/spaces'));
      await Future<void>.delayed(Duration.zero);

      expect(count, 0);
    });

    test('관리자 로그인의 401은 이벤트를 보내지 않는다', () async {
      final client = ApiClient(adapter: _FakeAdapter(unauthorized));
      var count = 0;
      client.adminUnauthorized.listen((_) => count++);

      await _catchError(client.post('/api/admin/auth/google', body: {}));
      await Future<void>.delayed(Duration.zero);

      expect(count, 0);
    });
  });
}
