import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/location/location_repository.dart';
import '../../../core/models/building.dart';
import '../../../core/utils/geo.dart';
import '../../search/models/candidate.dart';
import '../../search/models/origin.dart';
import '../data/directions_repository.dart';
import '../models/directions_stage.dart';
import '../models/walking_route.dart';

/// 지도 길찾기 · 내부 안내 · 이용 중(US-06).
class DirectionsViewModel extends ChangeNotifier {
  /// [origin]은 US-03에서 고른 건물, 고르지 않았으면 현재 위치다.
  /// 복구(US-04 ③ '여기로 갈게요', 새로고침)로 들어오면 출발점을 저장해 두지 않았으므로 null을 넘긴다.
  /// 그때는 [start]가 현재 위치로 다시 구하고, 그래도 없으면 [lacksOrigin](US-06 ②)이 된다.
  DirectionsViewModel({
    required DirectionsRepository directionsRepository,
    required LocationRepository locationRepository,
    Origin? origin,
    required this.destination,
    this.arrivalRadiusMeters = 30,
    this.pollInterval = const Duration(seconds: 10),
  }) : _directions = directionsRepository,
       _location = locationRepository,
       _start = origin?.point,
       _originLabel = origin?.label,
       _resolvingOrigin = origin == null;

  final DirectionsRepository _directions;
  final LocationRepository _location;

  final CandidateDetail destination;
  final double arrivalRadiusMeters;
  final Duration pollInterval;

  /// 경로의 출발점. 복구 중 아직 구하지 못했으면 null.
  GeoPoint? _start;
  String? _originLabel;
  bool _resolvingOrigin;

  DirectionsStage _stage = DirectionsStage.moving;
  WalkingRoute? _route;
  GeoPoint? _currentPosition;
  StreamSubscription<LocationFix>? _subscription;
  bool _disposed = false;

  DirectionsStage get stage => _stage;
  WalkingRoute? get route => _route;
  GeoPoint? get currentPosition => _currentPosition;

  /// 출발점 이름. 현재 위치에서 출발하면 건물 이름 대신 null일 수 있다.
  String? get originLabel => _originLabel;

  /// 복구로 들어와 현재 위치를 조회하는 중.
  bool get isResolvingOrigin => _resolvingOrigin;

  /// US-06 ② 복구 · 출발점 없음. 경로를 부르지 않고 목적지 핀만 둔 지도에 내부 안내 시트를 올린다.
  bool get lacksOrigin => _start == null && !_resolvingOrigin;

  /// 목적 건물 [arrivalRadiusMeters] 안. 제목을 '곧 도착해요'로 바꾸고 버튼을 강조한다.
  bool get isApproaching {
    final here = _currentPosition;
    if (here == null) return false;
    return distanceMeters(here, destination.buildingLocation) <= arrivalRadiusMeters;
  }

  /// 화면 진입. 경로를 받고 위치 갱신을 시작한다.
  /// 출발점이 없으면 현재 위치로 다시 구하고, 못 구하면 경로 없이 내부 안내(US-06 ②)로 둔다.
  Future<void> start() async {
    _subscription ??= _location.watch(interval: pollInterval).listen(_onFix);
    if (_start == null) {
      final fix = await _locate();
      _resolvingOrigin = false;
      if (fix == null) {
        _stage = DirectionsStage.inBuilding;
        _notify();
        return;
      }
      _start = fix.point;
    }
    await _fetchRoute();
  }

  /// US-06 ② '출발 건물 골라서 길찾기' 또는 복구 중 띄운 US-03에서 건물을 골랐다.
  /// 경로(U7)를 불러 이동 중(US-06 ① A)으로 전환한다.
  Future<void> chooseOrigin(Building building) async {
    _start = building.point;
    _originLabel = building.name;
    _resolvingOrigin = false;
    _stage = DirectionsStage.moving;
    _route = null;
    _notify();
    await _fetchRoute();
  }

  Future<LocationFix?> _locate() async {
    try {
      final permission = await _location.requestPermission();
      if (permission != LocationPermissionStatus.granted) return null;
      return await _location.currentFix();
    } on Exception {
      return null;
    }
  }

  Future<void> _fetchRoute() async {
    final from = _start!;
    try {
      _route = await _directions.fetchWalkingRoute(from: from, to: destination.buildingLocation);
    } on Exception {
      _route = WalkingRoute.straight(from, destination.buildingLocation);
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
