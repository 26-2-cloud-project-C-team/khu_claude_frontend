import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../utils/geo.dart';

/// 지도 위에 그릴 것. 값이 바뀌면 지도가 다시 그린다.
@immutable
class MapOverlays {
  const MapOverlays({
    this.currentLocation,
    this.destination,
    this.route = const [],
  });

  /// 경희블루 점.
  final GeoPoint? currentLocation;

  /// 경희레드 핀과 Primary Tint 강조 원.
  final GeoPoint? destination;

  /// 경희레드 선(흰 외곽선). 서버가 준 `path` 그대로다.
  final List<GeoPoint> route;

  @override
  bool operator ==(Object other) =>
      other is MapOverlays &&
      other.currentLocation == currentLocation &&
      other.destination == destination &&
      _listEquals(other.route, route);

  @override
  int get hashCode =>
      Object.hash(currentLocation, destination, Object.hashAll(route));
}

bool _listEquals(List<GeoPoint> a, List<GeoPoint> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// 지도를 움직이는 명령. [AppMap.onCreated]로 받는다.
abstract interface class MapController {
  /// [points]가 모두 보이도록 범위를 맞춘다. 출발점과 목적지를 함께 보여줄 때 쓴다.
  void fitBounds(List<GeoPoint> points, {EdgeInsets padding});

  /// '현재 위치로'처럼 한 점으로 옮긴다.
  void moveTo(GeoPoint point);
}

/// 실제 지도 구현. 앱은 카카오맵, 테스트는 Fake를 `provider`로 넣는다.
abstract interface class MapViewFactory {
  Widget create({
    required GeoPoint initialCenter,
    required MapOverlays overlays,
    ValueChanged<MapController>? onCreated,
  });
}

/// 화면이 쓰는 지도 위젯. 어떤 지도를 그릴지는 [MapViewFactory]가 정한다.
class AppMap extends StatelessWidget {
  const AppMap({
    super.key,
    required this.initialCenter,
    this.overlays = const MapOverlays(),
    this.onCreated,
  });

  final GeoPoint initialCenter;
  final MapOverlays overlays;
  final ValueChanged<MapController>? onCreated;

  @override
  Widget build(BuildContext context) {
    return context.read<MapViewFactory>().create(
      initialCenter: initialCenter,
      overlays: overlays,
      onCreated: onCreated,
    );
  }
}
