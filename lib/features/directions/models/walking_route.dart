import '../../../core/utils/geo.dart';
import '../../../core/utils/geo.dart' as geo show distanceMeters;

/// 출발점에서 목적 건물까지의 걷는 길(US-06 A).
class WalkingRoute {
  const WalkingRoute({
    required this.path,
    required this.distanceMeters,
    required this.minutes,
    this.isFallback = false,
  });

  /// U8 보행 경로를 받지 못했을 때 쓰는 직선 경로.
  factory WalkingRoute.straight(GeoPoint from, GeoPoint to) {
    final meters = geo.distanceMeters(from, to);
    return WalkingRoute(
      path: [from, to],
      distanceMeters: meters,
      minutes: walkingMinutes(meters),
      isFallback: true,
    );
  }

  final List<GeoPoint> path;
  final double distanceMeters;
  final int minutes;

  /// 직선 경로로 대체했는지. 보조 한 줄 문구를 '직선 450m'처럼 바꾸는 데 쓴다.
  final bool isFallback;
}
