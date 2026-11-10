import '../../../core/network/api_client.dart';
import '../../../core/utils/geo.dart';
import '../models/walking_route.dart';
import 'directions_repository.dart';

/// [DirectionsRepository]를 `/api/routes/walk`(U7)로 구현한다. 카카오 REST 키는 서버에만 있다.
class DirectionsRepositoryImpl implements DirectionsRepository {
  DirectionsRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<WalkingRoute> fetchWalkingRoute({
    required String origin,
    required String destination,
  }) async {
    final json = await _api.get(
      '/api/routes/walk',
      query: {'origin': origin, 'destination': destination},
    ) as Map<String, dynamic>;
    return WalkingRoute(
      path: [
        for (final p in json['path'] as List<dynamic>)
          GeoPoint(((p as Map)['lat'] as num).toDouble(), (p['lng'] as num).toDouble()),
      ],
      distanceMeters: (json['distanceM'] as num).toDouble(),
      minutes: json['walkMin'] as int,
      isFallback: json['approximate'] as bool,
    );
  }
}
