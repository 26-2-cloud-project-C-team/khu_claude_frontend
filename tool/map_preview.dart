// 카카오맵 래퍼를 실제 SDK로 확인하는 개발용 진입점이다. 실행 방법은 README의 '지도 확인'에 있다.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:team_frontend/core/map/app_map.dart';
import 'package:team_frontend/core/map/kakao_map.dart';
import 'package:team_frontend/core/theme/app_theme.dart';

// API 명세의 도보 경로 예시 좌표다. 실제 건물 위치와는 다르다.
const _origin = LatLng(37.2467, 127.0803);
const _destination = LatLng(37.2441, 127.0817);
const _route = [_origin, LatLng(37.2459, 127.0809), _destination];

void main() {
  runApp(
    Provider<MapViewFactory>.value(
      value: const KakaoMapViewFactory(),
      child: MaterialApp(theme: AppTheme.light, home: const _MapPreview()),
    ),
  );
}

class _MapPreview extends StatefulWidget {
  const _MapPreview();

  @override
  State<_MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<_MapPreview> {
  MapController? _map;
  var _current = _origin;

  // 현재 위치 갱신을 흉내 내려고 경로 위의 다음 점으로 옮긴다.
  void _step() => setState(
    () => _current = _route[(_route.indexOf(_current) + 1) % _route.length],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AppMap(
            initialCenter: _origin,
            overlays: MapOverlays(
              currentLocation: _current,
              destination: _destination,
              route: _route,
            ),
            onCreated: (map) {
              _map = map;
              map.fitBounds(const [_origin, _destination]);
            },
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 34,
            child: Row(
              children: [
                FilledButton(onPressed: _step, child: const Text('위치 이동')),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => _map?.moveTo(_current),
                  child: const Text('현재 위치로'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () =>
                      _map?.fitBounds(const [_origin, _destination]),
                  child: const Text('전체 보기'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
