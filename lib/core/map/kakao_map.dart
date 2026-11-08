import 'package:flutter/widgets.dart';

import '../utils/geo.dart';
import 'app_map.dart';
import 'kakao_map_stub.dart' if (dart.library.js_interop) 'kakao_map_web.dart';

/// 카카오맵 JS SDK로 그리는 [MapViewFactory]. 웹에서만 지도가 뜬다.
///
/// 앱 키는 `--dart-define=KAKAO_MAP_KEY=…`로 넘긴다. 키가 없으면 지도 대신 안내 문구를 보여준다.
class KakaoMapViewFactory implements MapViewFactory {
  const KakaoMapViewFactory();

  static const _appKey = String.fromEnvironment('KAKAO_MAP_KEY');

  @override
  Widget create({
    required GeoPoint initialCenter,
    required MapOverlays overlays,
    ValueChanged<MapController>? onCreated,
  }) {
    return KakaoMapView(
      appKey: _appKey,
      initialCenter: initialCenter,
      overlays: overlays,
      onCreated: onCreated,
    );
  }
}
