import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/network/api_client.dart';
import 'package:team_frontend/core/utils/geo.dart';
import 'package:team_frontend/features/directions/data/directions_repository_impl.dart';

import '../../../fakes/fake_http_adapter.dart';

void main() {
  test('U7 경로를 읽고 origin · destination을 쿼리로 보낸다', () async {
    final adapter = FakeHttpAdapter(
      (_) => jsonResponse(200, {
        'distanceM': 450,
        'walkMin': 7,
        'path': [
          {'lat': 37.2467, 'lng': 127.0803},
          {'lat': 37.2441, 'lng': 127.0817},
        ],
        'approximate': false,
      }),
    );

    final route = await DirectionsRepositoryImpl(ApiClient(adapter: adapter))
        .fetchWalkingRoute(origin: 'geo:37.2467,127.0803', destination: 'building:b1');

    expect(adapter.lastRequest.uri.path, '/api/routes/walk');
    expect(adapter.lastRequest.uri.queryParameters, {
      'origin': 'geo:37.2467,127.0803',
      'destination': 'building:b1',
    });
    expect(route.distanceMeters, 450);
    expect(route.minutes, 7);
    expect(route.path, const [GeoPoint(37.2467, 127.0803), GeoPoint(37.2441, 127.0817)]);
    expect(route.isFallback, isFalse);
  });

  test('approximate면 직선 경로로 표시한다', () async {
    final adapter = FakeHttpAdapter(
      (_) => jsonResponse(200, {
        'distanceM': 400,
        'walkMin': 6,
        'path': [
          {'lat': 37.2467, 'lng': 127.0803},
          {'lat': 37.2441, 'lng': 127.0817},
        ],
        'approximate': true,
      }),
    );

    final route = await DirectionsRepositoryImpl(ApiClient(adapter: adapter))
        .fetchWalkingRoute(origin: 'building:a', destination: 'building:b');

    expect(route.isFallback, isTrue);
  });
}
