import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/utils/geo.dart';

void main() {
  group('distanceMeters', () {
    test('같은 점이면 0이다', () {
      const p = GeoPoint(37.2465, 127.0802);
      expect(distanceMeters(p, p), 0);
    });

    test('위도 1도 차이는 약 111km다', () {
      expect(
        distanceMeters(const GeoPoint(0, 0), const GeoPoint(1, 0)),
        closeTo(111195, 200),
      );
    });
  });

  group('walkingMinutes', () {
    test('분속 70m로 올림하고 최소 1분이다', () {
      expect(walkingMinutes(0), 1);
      expect(walkingMinutes(70), 1);
      expect(walkingMinutes(71), 2);
    });

    test('화면 설계서 예시와 맞는다 (200m 3분, 400m 6분, 600m 9분)', () {
      expect(walkingMinutes(200), 3);
      expect(walkingMinutes(400), 6);
      expect(walkingMinutes(600), 9);
    });
  });
}
