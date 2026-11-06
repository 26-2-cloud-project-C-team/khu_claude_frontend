import 'dart:math' as math;

/// 위도·경도 한 점.
class GeoPoint {
  const GeoPoint(this.lat, this.lng);

  factory GeoPoint.fromJson(Map<String, dynamic> json) =>
      GeoPoint((json['lat'] as num).toDouble(), (json['lng'] as num).toDouble());

  final double lat;
  final double lng;

  @override
  bool operator ==(Object other) =>
      other is GeoPoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'GeoPoint($lat, $lng)';
}

const double _earthRadiusMeters = 6371000;

/// 두 점 사이의 직선(대권) 거리(m).
double distanceMeters(GeoPoint a, GeoPoint b) {
  double rad(double deg) => deg * math.pi / 180;
  final dLat = rad(b.lat - a.lat);
  final dLng = rad(b.lng - a.lng);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.lat)) * math.cos(rad(b.lat)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusMeters * math.asin(math.min(1, math.sqrt(h)));
}

/// 도보 속도. 화면 설계서 US-02 Check Point: 분속 70m.
const double walkingMetersPerMinute = 70;

/// 직선거리를 도보 시간(분)으로 바꾼다. 0m여도 1분으로 보여준다.
int walkingMinutes(double meters) =>
    math.max(1, (meters / walkingMetersPerMinute).ceil());
