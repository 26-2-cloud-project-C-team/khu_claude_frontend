import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/models/building.dart';

void main() {
  test('API 응답을 읽고 모르는 필드는 무시한다', () {
    final building = Building.fromJson({
      'id': '0192f5a1-7c3e-7b2a-9f10-3d4e5f6a7b8d',
      'name': '중앙도서관(대학본부)',
      'lat': 37.2441,
      'lng': 127,
      'floorRange': {'min': -1, 'max': 4},
      'unknown': true,
    });

    expect(building.id, '0192f5a1-7c3e-7b2a-9f10-3d4e5f6a7b8d');
    expect(building.name, '중앙도서관(대학본부)');
    expect(building.lat, 37.2441);
    expect(building.lng, 127.0);
    expect(building.floorRange.min, -1);
    expect(building.floorRange.max, 4);
  });

  test('id가 같으면 같은 건물이다', () {
    const a = Building(
      id: 'a',
      name: '공학관',
      lat: 0,
      lng: 0,
      floorRange: FloorRange(min: 1, max: 5),
    );
    const renamed = Building(
      id: 'a',
      name: '공과대학',
      lat: 0,
      lng: 0,
      floorRange: FloorRange(min: 1, max: 5),
    );

    expect(a, renamed);
  });

  group('FloorRange.floors', () {
    test('지하가 있으면 0층을 건너뛴다', () {
      expect(const FloorRange(min: -2, max: 3).floors, [-2, -1, 1, 2, 3]);
    });

    test('지하가 없으면 1층부터다', () {
      expect(const FloorRange(min: 1, max: 1).floors, [1]);
    });
  });
}
