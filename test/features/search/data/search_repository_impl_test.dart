import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/errors/app_exception.dart';
import 'package:team_frontend/core/location/location_repository.dart';
import 'package:team_frontend/core/models/noise_level.dart';
import 'package:team_frontend/core/models/purpose.dart';
import 'package:team_frontend/core/models/reinspection_category.dart';
import 'package:team_frontend/core/models/space_photo.dart';
import 'package:team_frontend/core/network/api_client.dart';
import 'package:team_frontend/core/utils/geo.dart';
import 'package:team_frontend/features/search/data/search_repository_impl.dart';
import 'package:team_frontend/features/search/models/condition_alternative.dart';
import 'package:team_frontend/features/search/models/origin.dart';
import 'package:team_frontend/features/search/models/requirement.dart';
import 'package:team_frontend/features/search/models/search_condition.dart';
import 'package:team_frontend/features/search/models/sort_key.dart';

import '../../../fakes/fake_http_adapter.dart';
import '../../../fakes/sample_space.dart';

void main() {
  const condition = SearchCondition(
    origin: BuildingOrigin(engineering),
    purpose: Purpose.solo,
    headcount: 2,
    requirements: {Requirement.charging, Requirement.quiet},
    sortKeys: {SortKey.charging, SortKey.distance},
  );

  SearchRepositoryImpl repoWith(FakeHttpAdapter adapter) =>
      SearchRepositoryImpl(ApiClient(adapter: adapter));

  test('U1 건물 목록을 Building으로 바꾼다', () async {
    final adapter = FakeHttpAdapter(
      (_) => jsonResponse(200, {
        'buildings': [
          {
            'id': 'b1',
            'name': '공학관',
            'lat': 37.2467,
            'lng': 127.0803,
            'floorRange': {'min': -1, 'max': 5},
          },
        ],
      }),
    );

    final buildings = await repoWith(adapter).fetchBuildings();

    expect(adapter.lastRequest.uri.path, '/api/buildings');
    expect(buildings.single.id, 'b1');
    expect(buildings.single.name, '공학관');
  });

  test('U2 요청은 명세의 쿼리 형식을 따른다', () async {
    final adapter = FakeHttpAdapter(
      (_) => jsonResponse(200, {
        'searchedAt': '2026-11-01T14:20:00+09:00',
        'total': 0,
        'candidates': <Object>[],
        'alternatives': <Object>[],
      }),
    );

    await repoWith(adapter).search(condition);

    final query = adapter.lastRequest.uri.queryParameters;
    expect(adapter.lastRequest.uri.path, '/api/spaces/search');
    expect(query['origin'], 'building:${engineering.id}');
    expect(query['purpose'], 'SOLO');
    expect(query['headcount'], '2');
    // 화면 순서대로 쉼표로 잇는다.
    expect(query['require'], 'QUIET,CHARGE');
    expect(query['sort'], 'NEAR,CHARGE');
    expect(query.containsKey('searchedAt'), isFalse);
  });

  test('현재 위치 출발점은 geo:{lat},{lng}로 보낸다', () async {
    final adapter = FakeHttpAdapter(
      (_) => jsonResponse(200, {
        'searchedAt': '2026-11-01T14:20:00+09:00',
        'total': 0,
        'candidates': <Object>[],
        'alternatives': <Object>[],
      }),
    );
    final here = SearchCondition(
      origin: CurrentLocationOrigin(
        fix: const LocationFix(point: GeoPoint(37.2467, 127.0803), accuracyMeters: 20),
        nearestBuilding: engineering,
      ),
      purpose: Purpose.team,
    );

    await repoWith(adapter).search(here);

    final query = adapter.lastRequest.uri.queryParameters;
    expect(query['origin'], 'geo:37.2467,127.0803');
    expect(query.containsKey('require'), isFalse);
    expect(query.containsKey('sort'), isFalse);
  });

  test('U2 후보를 상세와 함께 순서대로 읽는다', () async {
    final adapter = FakeHttpAdapter(
      (_) => jsonResponse(200, {
        'searchedAt': '2026-11-01T14:20:00+09:00',
        'total': 1,
        'candidates': [spaceJson(rank: 1, distanceM: 400, walkMin: 6)],
        'alternatives': <Object>[],
      }),
    );

    final result = await repoWith(adapter).search(condition);

    final c = result.candidates.single;
    expect(result.searchedAt, DateTime.parse('2026-11-01T14:20:00+09:00'));
    expect(c.spaceId, '0192f5a1-7c3e-7b2a-9f10-3d4e5f6a7c01');
    expect(c.name, '중앙도서관 4층 열람실');
    expect(c.buildingId, 'b-library');
    expect(c.floorLabel, '4층');
    expect(c.distanceMeters, 400);
    expect(c.walkMinutes, 6);
    expect(c.opensAt, '09:00');
    expect(c.chargeablePercent, 80);
    expect(c.noise, NoiseLevel.quiet);
    expect(c.ratingAverage, 4.6);
    expect(c.photos.map((p) => p.tag), [PhotoTag.entrance, PhotoTag.approach, PhotoTag.inside]);
    expect(c.recentReviews[1].text, isNull);
    expect(c.results.single.categories, [ReinspectionCategory.timeMood]);
  });

  test('U2 대안은 query의 조건으로 바꾸고 처음 검색의 출발점 · 목적은 유지한다', () async {
    final adapter = FakeHttpAdapter(
      (_) => jsonResponse(200, {
        'searchedAt': '2026-11-01T14:20:00+09:00',
        'total': 0,
        'candidates': <Object>[],
        'alternatives': [
          {
            'type': 'CLEAR_REQUIREMENTS',
            'count': 12,
            'query': {
              'origin': 'building:${engineering.id}',
              'purpose': 'SOLO',
              'headcount': 2,
              'require': <Object>[],
              'sort': ['NEAR'],
              'searchedAt': '2026-11-01T14:20:00+09:00',
            },
          },
          {
            'type': 'DROP_REQUIREMENT',
            'requirement': 'QUIET',
            'count': 8,
            'query': {
              'origin': 'building:${engineering.id}',
              'purpose': 'SOLO',
              'headcount': 2,
              'require': ['CHARGE'],
              'sort': ['NEAR'],
            },
          },
          {'type': 'UNKNOWN', 'count': 3, 'query': <String, Object>{}},
        ],
      }),
    );

    final result = await repoWith(adapter).search(condition);

    expect(result.alternatives.map((a) => a.alternative), [
      const ClearRequirements(),
      const RemoveRequirement(Requirement.quiet),
    ]);
    final drop = result.alternatives[1];
    expect(drop.count, 8);
    expect(drop.condition.origin, condition.origin);
    expect(drop.condition.purpose, Purpose.solo);
    expect(drop.condition.requirements, {Requirement.charging});
    expect(drop.condition.sortKeys, {SortKey.distance});
  });

  test('대안 재검색은 처음 검색의 searchedAt을 KST로 보낸다', () async {
    final adapter = FakeHttpAdapter(
      (_) => jsonResponse(200, {
        'searchedAt': '2026-11-01T14:20:00+09:00',
        'total': 0,
        'candidates': <Object>[],
        'alternatives': <Object>[],
      }),
    );

    await repoWith(adapter)
        .search(condition, searchedAt: DateTime.parse('2026-11-01T14:20:00+09:00'));

    expect(adapter.lastRequest.uri.queryParameters['searchedAt'], '2026-11-01T14:20:00+09:00');
  });

  test('U3 공간 하나를 읽고, 도보 시간 · 거리는 없다', () async {
    final adapter = FakeHttpAdapter((_) => jsonResponse(200, spaceJson(id: 'abc')));

    final space = await repoWith(adapter).fetchSpace('abc');

    expect(adapter.lastRequest.uri.path, '/api/spaces/abc');
    expect(space!.spaceId, 'abc');
    expect(space.walkMinutes, isNull);
    expect(space.distanceMeters, isNull);
  });

  test('U3 404 · 400이면 볼 수 없는 공간(null)이다', () async {
    for (final status in [404, 400]) {
      final adapter = FakeHttpAdapter(
        (_) => jsonResponse(status, {
          'error': {'code': 'SPACE_NOT_FOUND', 'message': '공간을 찾을 수 없습니다.'},
        }),
      );

      expect(await repoWith(adapter).fetchSpace('abc'), isNull);
    }
  });

  test('U3 5xx는 그대로 던진다', () async {
    final adapter = FakeHttpAdapter((_) => jsonResponse(500, {}));

    expect(repoWith(adapter).fetchSpace('abc'), throwsA(isA<AppException>()));
  });
}
