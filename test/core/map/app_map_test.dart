import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:team_frontend/core/map/app_map.dart';
import 'package:team_frontend/core/utils/geo.dart';
import 'package:team_frontend/core/map/kakao_map.dart';

import '../../fakes/fake_map_view_factory.dart';
import '../../helpers/pump_test_app.dart';

const _origin = GeoPoint(37.2467, 127.0803);
const _destination = GeoPoint(37.2441, 127.0817);

/// 길찾기 화면이 지도를 쓰는 방식을 줄인 예시.
class _DirectionsExample extends StatefulWidget {
  const _DirectionsExample({required this.current});

  final GeoPoint current;

  @override
  State<_DirectionsExample> createState() => _DirectionsExampleState();
}

class _DirectionsExampleState extends State<_DirectionsExample> {
  MapController? _map;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: AppMap(
            initialCenter: _origin,
            overlays: MapOverlays(
              currentLocation: widget.current,
              destination: _destination,
              route: const [_origin, _destination],
            ),
            onCreated: (map) {
              _map = map;
              map.fitBounds(const [_origin, _destination]);
            },
          ),
        ),
        TextButton(
          onPressed: () => _map?.moveTo(widget.current),
          child: const Text('현재 위치로'),
        ),
      ],
    );
  }
}

void main() {
  group('FakeMapViewFactory로 지도를 쓰는 화면 테스트', () {
    testWidgets('지도가 만들어지면 출발점과 목적지가 보이도록 범위를 맞춘다', (tester) async {
      final map = FakeMapViewFactory();

      await tester.pumpTestApp(
        const _DirectionsExample(current: _origin),
        providers: [Provider<MapViewFactory>.value(value: map)],
      );
      await tester.pump();

      expect(map.initialCenter, _origin);
      expect(
        map.overlays,
        const MapOverlays(
          currentLocation: _origin,
          destination: _destination,
          route: [_origin, _destination],
        ),
      );
      expect(map.controller.fittedBounds, [
        [_origin, _destination],
      ]);
    });

    testWidgets("'현재 위치로'를 누르면 현재 위치로 옮긴다", (tester) async {
      final map = FakeMapViewFactory();
      const current = GeoPoint(37.2455, 127.0810);

      await tester.pumpTestApp(
        const _DirectionsExample(current: current),
        providers: [Provider<MapViewFactory>.value(value: map)],
      );
      await tester.pump();
      await tester.tap(find.text('현재 위치로'));

      expect(map.controller.movedTo, [current]);
    });
  });

  test('경로 좌표를 API 응답에서 읽는다', () {
    final path = [
      for (final point in [
        {'lat': 37.2467, 'lng': 127.0803},
        {'lat': 37.2441, 'lng': 127},
      ])
        GeoPoint.fromJson(point),
    ];

    expect(path, const [GeoPoint(37.2467, 127.0803), GeoPoint(37.2441, 127.0)]);
  });

  testWidgets('카카오맵 구현은 웹이 아니면 안내 문구를 보여준다', (tester) async {
    await tester.pumpTestApp(
      const AppMap(initialCenter: _origin),
      providers: [
        Provider<MapViewFactory>.value(value: const KakaoMapViewFactory()),
      ],
    );

    expect(find.text('지도는 웹에서만 볼 수 있어요'), findsOneWidget);
  });
}
