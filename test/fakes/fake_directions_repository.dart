import 'package:team_frontend/features/directions/data/directions_repository.dart';
import 'package:team_frontend/features/directions/models/walking_route.dart';

class FakeDirectionsRepository implements DirectionsRepository {
  FakeDirectionsRepository({this.route, this.fail = false});

  WalkingRoute? route;
  bool fail;

  /// 받은 (origin, destination) 쿼리 값.
  final List<(String, String)> calls = [];

  @override
  Future<WalkingRoute> fetchWalkingRoute({
    required String origin,
    required String destination,
  }) async {
    calls.add((origin, destination));
    if (fail || route == null) throw Exception('U7 실패');
    return route!;
  }
}
