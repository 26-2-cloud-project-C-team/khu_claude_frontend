import 'package:flutter/widgets.dart';

import '../utils/geo.dart';
import 'app_map.dart';
import 'map_placeholder.dart';

class KakaoMapView extends StatelessWidget {
  const KakaoMapView({
    super.key,
    required this.appKey,
    required this.initialCenter,
    required this.overlays,
    this.onCreated,
  });

  final String appKey;
  final GeoPoint initialCenter;
  final MapOverlays overlays;
  final ValueChanged<MapController>? onCreated;

  @override
  Widget build(BuildContext context) =>
      const MapPlaceholder('지도는 웹에서만 볼 수 있어요');
}
