import '../models/walking_route.dart';

abstract class DirectionsRepository {
  /// U7 도보 경로. [origin] · [destination]은 `building:{buildingId}` 또는 `geo:{lat},{lng}`.
  /// 카카오 경로를 못 찾으면 서버가 직선 경로(`approximate: true`)를 준다.
  Future<WalkingRoute> fetchWalkingRoute({required String origin, required String destination});
}
