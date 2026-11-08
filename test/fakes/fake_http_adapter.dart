import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:team_frontend/core/network/api_client.dart';

/// 정해진 응답을 돌려주는 HTTP 어댑터. Repository 구현체 테스트에서 [ApiClient]에 넣는다.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;
  final List<RequestOptions> requests = [];
  final List<Object?> bodies = [];

  RequestOptions get lastRequest => requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (requestStream != null) {
      final raw = utf8.decode(await requestStream.expand((chunk) => chunk).toList());
      bodies.add(raw.isEmpty ? null : jsonDecode(raw));
    } else {
      bodies.add(null);
    }
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(int statusCode, Object? body) => ResponseBody.fromString(
  jsonEncode(body),
  statusCode,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

/// API 명세 U2 · U3 응답 예시의 공간 하나.
Map<String, dynamic> spaceJson({
  String id = '0192f5a1-7c3e-7b2a-9f10-3d4e5f6a7c01',
  int? rank,
  int? distanceM,
  int? walkMin,
}) => {
  'rank': ?rank,
  'distanceM': ?distanceM,
  'walkMin': ?walkMin,
  'id': id,
  'location': {
    'name': '중앙도서관 4층 열람실',
    'buildingId': 'b-library',
    'floor': 4,
    'locationDetail': '엘리베이터에서 내려 왼쪽 끝',
    'purposes': ['SOLO'],
  },
  'building': {'id': 'b-library', 'name': '중앙도서관(대학본부)', 'lat': 37.2441, 'lng': 127.0817},
  'photos': {
    'entrance': {'id': 'p1', 'url': 'https://cdn.example.com/entrance.webp'},
    'approach': {'id': 'p2', 'url': 'https://cdn.example.com/approach.webp'},
    'inside': {'id': 'p3', 'url': 'https://cdn.example.com/inside.webp'},
    'extras': <Object>[],
  },
  'rules': {
    'isCafe': false,
    'talkAllowed': false,
    'hours': {'open': '09:00', 'close': '22:00'},
    'noiseLevel': 'QUIET',
  },
  'facilities': {'tableCount': 10, 'maxSeatsPerTable': 8, 'chargeableTables': 8, 'freeWifi': true},
  'chargeableRatio': 80,
  'impressions': {
    'pros': '테이블마다 콘센트가 있어요.',
    'cons': '오후에는 자리가 빨리 차요.',
    'note': '학생증 태그로 들어가요. 취식은 안 돼요.',
  },
  'ratingSummary': {'avg': 4.6, 'count': 32},
  'recentReviews': [
    {'rating': 5, 'comment': '조용해요', 'createdAt': '2026-10-12T18:40:00+09:00'},
    {'rating': 4, 'comment': null, 'createdAt': '2026-10-11T13:05:00+09:00'},
  ],
  'reinspectionResults': [
    {
      'categories': ['TIME_MOOD'],
      'result': '이용 시간을 09:00 – 21:30으로 고쳤어요.',
      'resolvedAt': '2026-10-12T10:30:00+09:00',
    },
  ],
};
