import 'dart:async';

import 'package:team_frontend/core/location/location_repository.dart';

class FakeLocationRepository implements LocationRepository {
  FakeLocationRepository({
    this.permission = LocationPermissionStatus.granted,
    this.fix,
  });

  LocationPermissionStatus permission;
  LocationFix? fix;

  final StreamController<LocationFix> _positions = StreamController.broadcast();
  int watchCount = 0;

  /// watch 구독자에게 위치를 흘려보낸다.
  void emit(LocationFix fix) => _positions.add(fix);

  bool get hasListener => _positions.hasListener;

  @override
  Future<LocationPermissionStatus> requestPermission() async => permission;

  @override
  Future<LocationFix?> currentFix() async =>
      permission == LocationPermissionStatus.granted ? fix : null;

  @override
  Stream<LocationFix> watch({Duration interval = const Duration(seconds: 10)}) {
    watchCount++;
    return _positions.stream;
  }
}
