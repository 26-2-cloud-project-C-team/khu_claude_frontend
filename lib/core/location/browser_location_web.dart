import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../utils/geo.dart';
import 'location_repository.dart';

/// `navigator.geolocation`으로 위치를 구한다. 권한 팝업은 첫 조회 때 브라우저가 띄운다.
class BrowserLocationRepository implements LocationRepository {
  /// PositionError.PERMISSION_DENIED
  static const _permissionDenied = 1;

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    try {
      await _position();
      return LocationPermissionStatus.granted;
    } on _LocationError catch (e) {
      // 시간 초과 · 위치 없음은 권한은 있지만 조회에 실패한 것이라 currentFix가 null을 준다.
      return e.code == _permissionDenied
          ? LocationPermissionStatus.denied
          : LocationPermissionStatus.granted;
    }
  }

  @override
  Future<LocationFix?> currentFix() async {
    try {
      final p = await _position();
      return LocationFix(
        point: GeoPoint(p.coords.latitude, p.coords.longitude),
        accuracyMeters: p.coords.accuracy,
      );
    } on _LocationError {
      return null;
    }
  }

  @override
  Stream<LocationFix> watch({Duration interval = const Duration(seconds: 10)}) =>
      Stream.periodic(interval)
          .asyncMap((_) => currentFix())
          .where((fix) => fix != null)
          .cast<LocationFix>();

  Future<web.GeolocationPosition> _position() {
    final done = Completer<web.GeolocationPosition>();
    web.window.navigator.geolocation.getCurrentPosition(
      ((web.GeolocationPosition p) => done.complete(p)).toJS,
      ((web.GeolocationPositionError e) => done.completeError(_LocationError(e.code))).toJS,
      web.PositionOptions(enableHighAccuracy: true, timeout: 10000, maximumAge: 5000),
    );
    return done.future;
  }
}

class _LocationError implements Exception {
  const _LocationError(this.code);

  final int code;
}
