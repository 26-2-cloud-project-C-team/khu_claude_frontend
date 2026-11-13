import '../../../core/location/location_repository.dart';
import '../../../core/models/building.dart';
import '../../../core/utils/geo.dart';

/// 출발점. 현재 위치(US-01 A) 또는 직접 고른 건물(US-03).
sealed class Origin {
  const Origin();

  /// 거리 계산과 길찾기(US-06)의 기준점.
  GeoPoint get point;

  /// 조건 요약 시트에 보여줄 이름.
  String get label;

  /// U2 `origin` · U7 `origin` 쿼리 값. `building:{buildingId}` 또는 `geo:{lat},{lng}`.
  String get apiParam;
}

class CurrentLocationOrigin extends Origin {
  const CurrentLocationOrigin({required this.fix, this.nearestBuilding});

  final LocationFix fix;

  /// 현재 위치에서 [nearbyBuildingMaxMeters] 안의 가장 가까운 건물. 카드 문구('공학관 앞')에만 쓴다.
  /// 근처에 건물이 없으면 null이고 '현재 위치'로 보여준다. 검색 거리는 [fix] 좌표로 계산한다.
  final Building? nearestBuilding;

  @override
  GeoPoint get point => fix.point;

  @override
  String get label => nearestBuilding?.name ?? '현재 위치';

  @override
  String get apiParam => 'geo:${fix.point.lat},${fix.point.lng}';
}

class BuildingOrigin extends Origin {
  const BuildingOrigin(this.building);

  final Building building;

  @override
  GeoPoint get point => building.point;

  @override
  String get label => building.name;

  @override
  String get apiParam => 'building:${building.id}';

  @override
  bool operator ==(Object other) => other is BuildingOrigin && other.building == building;

  @override
  int get hashCode => building.hashCode;
}

/// 현재 위치 카드에 '<건물명> 앞'으로 붙일 수 있는 최대 거리(m).
///
/// U1은 공개 공간이 있는 건물만 주므로, 목록에서 가장 가까운 건물이 실제로는 먼 건물일 수 있다.
// TODO: 전체 건물을 주는 공개 API가 생기면 그 목록으로 계산한다.
const double nearbyBuildingMaxMeters = 150;

/// [from]에서 [maxMeters] 안의 가장 가까운 건물. 목록이 비었거나 모두 그보다 멀면 null.
Building? nearestBuilding(
  GeoPoint from,
  Iterable<Building> buildings, {
  double maxMeters = nearbyBuildingMaxMeters,
}) {
  Building? best;
  var bestDistance = double.infinity;
  for (final b in buildings) {
    final d = distanceMeters(from, b.point);
    if (d < bestDistance) {
      best = b;
      bestDistance = d;
    }
  }
  return bestDistance <= maxMeters ? best : null;
}
