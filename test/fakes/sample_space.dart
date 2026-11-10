import 'package:team_frontend/core/models/building.dart';
import 'package:team_frontend/core/models/noise_level.dart';
import 'package:team_frontend/core/utils/geo.dart';
import 'package:team_frontend/features/search/models/candidate.dart';

const _floors = FloorRange(min: -1, max: 5);

const engineering = Building(
  id: 'b-engineering',
  name: '공학관',
  lat: 37.2465,
  lng: 127.0802,
  floorRange: _floors,
);
const centralLibrary = Building(
  id: 'b-library',
  name: '중앙도서관(대학본부)',
  lat: 37.2410,
  lng: 127.0800,
  floorRange: _floors,
);
const lifeScience = Building(
  id: 'b-life',
  name: '생명과학대학관',
  lat: 37.2430,
  lng: 127.0820,
  floorRange: _floors,
);

/// 테스트용 공간. [id]가 숫자면 그대로 문자열로 바꿔 `spaceId`로 쓴다('1', '2', …).
CandidateDetail sampleCandidate(
  Object id, {
  GeoPoint buildingLocation = const GeoPoint(37.2410, 127.0800),
  int tableCount = 10,
  int chargeableTableCount = 8,
  int? distanceMeters = 400,
  int? walkMinutes = 6,
}) {
  return CandidateDetail(
    spaceId: '$id',
    name: '공간 $id',
    buildingId: centralLibrary.id,
    buildingName: '중앙도서관(대학본부)',
    buildingLocation: buildingLocation,
    floor: 4,
    locationGuide: '엘리베이터에서 내려 왼쪽 끝',
    photos: const [],
    distanceMeters: distanceMeters,
    walkMinutes: walkMinutes,
    opensAt: '00:00',
    closesAt: '00:00',
    ratingAverage: 4.6,
    ratingCount: 32,
    tableCount: tableCount,
    maxPerTable: 8,
    chargeableTableCount: chargeableTableCount,
    chargeablePercent: tableCount == 0 ? 0 : (chargeableTableCount * 100 / tableCount).round(),
    freeWifi: true,
    noise: NoiseLevel.quiet,
    isCafe: false,
  );
}
