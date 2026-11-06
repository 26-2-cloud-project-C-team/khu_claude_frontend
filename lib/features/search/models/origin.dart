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
}

class CurrentLocationOrigin extends Origin {
  const CurrentLocationOrigin({required this.fix, required this.nearestBuilding});

  final LocationFix fix;

  /// 현재 위치에서 가장 가까운 건물. 카드 문구('공학관 앞')에만 쓴다.
  final Building nearestBuilding;

  @override
  GeoPoint get point => fix.point;

  @override
  String get label => nearestBuilding.name;
}

class BuildingOrigin extends Origin {
  const BuildingOrigin(this.building);

  final Building building;

  @override
  GeoPoint get point => building.point;

  @override
  String get label => building.name;

  @override
  bool operator ==(Object other) => other is BuildingOrigin && other.building == building;

  @override
  int get hashCode => building.hashCode;
}

/// [from]에서 가장 가까운 건물. 목록이 비면 null.
Building? nearestBuilding(GeoPoint from, Iterable<Building> buildings) {
  Building? best;
  var bestDistance = double.infinity;
  for (final b in buildings) {
    final d = distanceMeters(from, b.point);
    if (d < bestDistance) {
      best = b;
      bestDistance = d;
    }
  }
  return best;
}
