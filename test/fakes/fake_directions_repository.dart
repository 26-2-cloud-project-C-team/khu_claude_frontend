import 'package:team_frontend/core/utils/geo.dart';
import 'package:team_frontend/features/directions/data/directions_repository.dart';
import 'package:team_frontend/features/directions/models/walking_route.dart';

class FakeDirectionsRepository implements DirectionsRepository {
  FakeDirectionsRepository({this.route, this.fail = false});

  WalkingRoute? route;
  bool fail;

  @override
  Future<WalkingRoute> fetchWalkingRoute({required GeoPoint from, required GeoPoint to}) async {
    if (fail || route == null) throw Exception('U8 실패');
    return route!;
  }
}
