import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/location/location_repository.dart';
import 'package:team_frontend/core/utils/geo.dart';
import 'package:team_frontend/features/search/models/origin.dart';

import '../../../fakes/sample_space.dart';

void main() {
  group('nearestBuilding', () {
    const buildings = [engineering, centralLibrary, lifeScience];

    test('150m 안이면 가장 가까운 건물을 준다', () {
      // 공학관에서 북쪽으로 약 100m
      const near = GeoPoint(37.2474, 127.0802);

      expect(nearestBuilding(near, buildings), engineering);
    });

    test('가장 가까운 건물도 150m보다 멀면 null이다', () {
      // 공학관에서 북쪽으로 약 390m
      const far = GeoPoint(37.2500, 127.0802);

      expect(distanceMeters(far, engineering.point), greaterThan(nearbyBuildingMaxMeters));
      expect(nearestBuilding(far, buildings), isNull);
    });

    test('목록이 비면 null이다', () {
      expect(nearestBuilding(engineering.point, const []), isNull);
    });
  });

  group('CurrentLocationOrigin.label', () {
    const fix = LocationFix(point: GeoPoint(37.2465, 127.0802), accuracyMeters: 20);

    test('가까운 건물이 있으면 건물 이름이다', () {
      expect(const CurrentLocationOrigin(fix: fix, nearestBuilding: engineering).label, '공학관');
    });

    test('가까운 건물이 없으면 현재 위치다', () {
      expect(const CurrentLocationOrigin(fix: fix).label, '현재 위치');
    });
  });
}
