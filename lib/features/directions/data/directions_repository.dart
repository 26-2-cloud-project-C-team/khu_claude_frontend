import '../../../core/utils/geo.dart';
import '../models/walking_route.dart';

abstract class DirectionsRepository {
  /// U8 보행 경로. 아직 확정 전이라 실패하면 호출하는 쪽이 직선 경로로 대체한다.
  Future<WalkingRoute> fetchWalkingRoute({required GeoPoint from, required GeoPoint to});
}
