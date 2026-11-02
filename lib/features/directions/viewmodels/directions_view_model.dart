import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/location/location_repository.dart';
import '../../../core/utils/geo.dart';
import '../../search/models/candidate.dart';
import '../../search/models/origin.dart';
import '../data/directions_repository.dart';
import '../models/directions_stage.dart';
import '../models/walking_route.dart';

/// 지도 길찾기 · 내부 안내 · 이용 중(US-06).
class DirectionsViewModel extends ChangeNotifier {
  DirectionsViewModel({
    required DirectionsRepository directionsRepository,
    required LocationRepository locationRepository,
    required this.origin,
    required this.destination,
    this.arrivalRadiusMeters = 30,
    this.pollInterval = const Duration(seconds: 10),
  })  : _directions = directionsRepository,
        _location = locationRepository;

  final DirectionsRepository _directions;
  final LocationRepository _location;

  /// US-03에서 고른 건물, 고르지 않았으면 현재 위치.
  final Origin origin;
  final CandidateDetail destination;
  final double arrivalRadiusMeters;
  final Duration pollInterval;

  DirectionsStage _stage = DirectionsStage.moving;
  WalkingRoute? _route;
  GeoPoint? _currentPosition;
  StreamSubscription<LocationFix>? _subscription;
  bool _disposed = false;

  DirectionsStage get stage => _stage;
  WalkingRoute? get route => _route;
  GeoPoint? get currentPosition => _currentPosition;

  /// 목적 건물 [arrivalRadiusMeters] 안. 제목을 '곧 도착해요'로 바꾸고 버튼을 강조한다.
  bool get isApproaching {
    final here = _currentPosition;
    if (here == null) return false;
    return distanceMeters(here, destination.buildingLocation) <= arrivalRadiusMeters;
  }

  /// 화면 진입. 경로를 받고 위치 갱신을 시작한다.
  Future<void> start() async {
    _subscription ??= _location.watch(interval: pollInterval).listen(_onFix);
    try {
      _route = await _directions.fetchWalkingRoute(
        from: origin.point,
        to: destination.buildingLocation,
      );
    } on Exception {
      _route = WalkingRoute.straight(origin.point, destination.buildingLocation);
    }
    _notify();
  }

  void _onFix(LocationFix fix) {
    _currentPosition = fix.point;
    _notify();
  }

  /// A '건물에 도착했어요' → B.
  void arriveAtBuilding() {
    if (_stage != DirectionsStage.moving) return;
    _stage = DirectionsStage.inBuilding;
    _notify();
  }

  /// B '공간에 도착했어요', A·B '길 안내 없이 바로 이용하기' → C.
  void startUsing() {
    if (_stage == DirectionsStage.inUse) return;
    _stage = DirectionsStage.inUse;
    _stopWatching();
    _notify();
  }

  void _stopWatching() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopWatching();
    super.dispose();
  }
}
