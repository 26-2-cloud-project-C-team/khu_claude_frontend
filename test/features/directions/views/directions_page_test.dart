import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:team_frontend/core/map/app_map.dart';
import 'package:team_frontend/core/utils/geo.dart';
import 'package:team_frontend/core/location/location_repository.dart';
import 'package:team_frontend/core/models/building.dart';
import 'package:team_frontend/features/directions/models/walking_route.dart';
import 'package:team_frontend/features/directions/viewmodels/directions_view_model.dart';
import 'package:team_frontend/features/directions/views/directions_page.dart';
import 'package:team_frontend/features/search/models/origin.dart';

import '../../../helpers/pump_test_app.dart';
import '../../../fakes/fake_directions_repository.dart';
import '../../../fakes/fake_location_repository.dart';
import '../../../fakes/fake_map_view_factory.dart';
import '../../../fakes/sample_space.dart';

void main() {
  testWidgets('이동 중 → 건물 도착 → 이용 중으로 진행한다', (tester) async {
    final vm = DirectionsViewModel(
      directionsRepository: FakeDirectionsRepository(
        route: const WalkingRoute(path: [], distanceMeters: 450, minutes: 6),
      ),
      locationRepository: FakeLocationRepository(),
      origin: BuildingOrigin(engineering),
      destination: sampleCandidate(1),
    );
    addTearDown(vm.dispose);
    var reviews = 0;
    await tester.pumpTestApp(
      DirectionsPage(
        viewModel: vm,
        onChooseOrigin: () async => null,
        onReview: () => reviews++,
        onReinspect: () {},
        onClose: () {},
      ),
      providers: [Provider<MapViewFactory>.value(value: FakeMapViewFactory())],
    );
    await tester.pumpAndSettle();

    expect(find.text('중앙도서관(대학본부)까지 도보 6분'), findsOneWidget);
    expect(find.text('걷는 길 450m'), findsOneWidget);

    await tester.tap(find.text('건물에 도착했어요'));
    await tester.pumpAndSettle();
    expect(find.text('4층으로 올라가세요'), findsOneWidget);

    await tester.tap(find.text('공간에 도착했어요'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이용 의견 남기기'));

    expect(reviews, 1);
  });

  testWidgets('복구 · 출발점 없음이면 US-03을 먼저 띄우고, 닫으면 핀만 있는 내부 안내에 남는다', (tester) async {
    final vm = DirectionsViewModel(
      directionsRepository: FakeDirectionsRepository(
        route: const WalkingRoute(path: [], distanceMeters: 450, minutes: 6),
      ),
      locationRepository: FakeLocationRepository(permission: LocationPermissionStatus.denied),
      destination: sampleCandidate(1),
    );
    addTearDown(vm.dispose);
    final picks = <Building?>[null, engineering];
    var asked = 0;
    await tester.pumpTestApp(
      DirectionsPage(
        viewModel: vm,
        onChooseOrigin: () async => picks[asked++],
        onReview: () {},
        onReinspect: () {},
        onClose: () {},
      ),
      providers: [Provider<MapViewFactory>.value(value: FakeMapViewFactory())],
    );
    await tester.pumpAndSettle();

    expect(asked, 1);
    expect(find.text('내부 안내'), findsNWidgets(2));
    expect(find.text('2/2 · 건물 도착'), findsNothing);
    expect(find.text('4층으로 올라가세요'), findsOneWidget);
    expect(find.text('길 안내 없이 바로 이용하기'), findsNothing);

    await tester.tap(find.text('출발 건물 골라서 길찾기'));
    await tester.pumpAndSettle();

    expect(asked, 2);
    expect(find.text('1/2 · 이동 중'), findsOneWidget);
    expect(find.text('걷는 길 450m'), findsOneWidget);
  });

  group('지도', () {
    const path = [
      GeoPoint(37.2465, 127.0802),
      GeoPoint(37.2440, 127.0801),
      GeoPoint(37.2410, 127.0800),
    ];

    Future<FakeMapViewFactory> pumpWith(
      WidgetTester tester,
      DirectionsViewModel vm, {
      Future<Building?> Function()? onChooseOrigin,
    }) async {
      final map = FakeMapViewFactory();
      await tester.pumpTestApp(
        DirectionsPage(
          viewModel: vm,
          onChooseOrigin: onChooseOrigin ?? () async => null,
          onReview: () {},
          onReinspect: () {},
          onClose: () {},
        ),
        providers: [Provider<MapViewFactory>.value(value: map)],
      );
      await tester.pumpAndSettle();
      return map;
    }

    testWidgets('목적지 핀과 서버가 준 경로를 그리고, 현재 위치가 오면 점을 옮긴다', (tester) async {
      final location = FakeLocationRepository();
      final vm = DirectionsViewModel(
        directionsRepository: FakeDirectionsRepository(
          route: const WalkingRoute(path: path, distanceMeters: 450, minutes: 6),
        ),
        locationRepository: location,
        origin: BuildingOrigin(engineering),
        destination: sampleCandidate(1),
      );
      addTearDown(vm.dispose);

      final map = await pumpWith(tester, vm);

      expect(map.overlays!.destination, sampleCandidate(1).buildingLocation);
      expect(map.overlays!.route, path);
      expect(map.overlays!.currentLocation, isNull);

      const here = GeoPoint(37.2450, 127.0801);
      location.emit(const LocationFix(point: here, accuracyMeters: 10));
      // 스트림 전달(마이크로태스크) 뒤 ViewModel 알림으로 다시 그려지는 프레임까지 기다린다.
      await tester.pump();
      await tester.pump();

      expect(map.overlays!.currentLocation, here);
    });

    testWidgets('진입하면 출발점과 목적지가 모두 보이게 범위를 맞춘다', (tester) async {
      final vm = DirectionsViewModel(
        directionsRepository: FakeDirectionsRepository(
          route: const WalkingRoute(path: path, distanceMeters: 450, minutes: 6),
        ),
        locationRepository: FakeLocationRepository(),
        origin: BuildingOrigin(engineering),
        destination: sampleCandidate(1),
      );
      addTearDown(vm.dispose);

      final map = await pumpWith(tester, vm);

      expect(map.initialCenter, engineering.point);
      expect(map.controller.fittedBounds, [
        [engineering.point, sampleCandidate(1).buildingLocation],
      ]);
      expect(map.controller.movedTo, isEmpty);
    });

    testWidgets('② 출발점이 없으면 경로 · 현재 위치 없이 목적지를 가운데로 옮긴다', (tester) async {
      final location = FakeLocationRepository(permission: LocationPermissionStatus.denied);
      final vm = DirectionsViewModel(
        directionsRepository: FakeDirectionsRepository(
          route: const WalkingRoute(path: path, distanceMeters: 450, minutes: 6),
        ),
        locationRepository: location,
        destination: sampleCandidate(1),
      );
      addTearDown(vm.dispose);

      final map = await pumpWith(tester, vm);
      location.emit(const LocationFix(point: GeoPoint(37.2450, 127.0801), accuracyMeters: 10));
      await tester.pump();

      final destination = sampleCandidate(1).buildingLocation;
      expect(vm.lacksOrigin, isTrue);
      expect(map.overlays!.route, isEmpty);
      expect(map.overlays!.currentLocation, isNull);
      expect(map.overlays!.destination, destination);
      expect(map.controller.movedTo, [destination]);
      expect(map.controller.fittedBounds, isEmpty);
    });

    testWidgets('②에서 출발 건물을 고르면 경로를 그리고 다시 범위를 맞춘다', (tester) async {
      final vm = DirectionsViewModel(
        directionsRepository: FakeDirectionsRepository(
          route: const WalkingRoute(path: path, distanceMeters: 450, minutes: 6),
        ),
        locationRepository: FakeLocationRepository(permission: LocationPermissionStatus.denied),
        destination: sampleCandidate(1),
      );
      addTearDown(vm.dispose);
      final picks = <Building?>[null, engineering];
      var asked = 0;

      final map = await pumpWith(tester, vm, onChooseOrigin: () async => picks[asked++]);
      await tester.tap(find.text('출발 건물 골라서 길찾기'));
      await tester.pumpAndSettle();

      expect(map.overlays!.route, path);
      expect(map.controller.fittedBounds.last, [
        engineering.point,
        sampleCandidate(1).buildingLocation,
      ]);
    });

    testWidgets("'현재 위치로'를 누르면 지도를 현재 위치로 옮긴다", (tester) async {
      final location = FakeLocationRepository();
      final vm = DirectionsViewModel(
        directionsRepository: FakeDirectionsRepository(
          route: const WalkingRoute(path: path, distanceMeters: 450, minutes: 6),
        ),
        locationRepository: location,
        origin: BuildingOrigin(engineering),
        destination: sampleCandidate(1),
      );
      addTearDown(vm.dispose);

      final map = await pumpWith(tester, vm);
      // 현재 위치를 받기 전에는 옮길 곳이 없어 버튼이 없다.
      expect(find.byTooltip('현재 위치로'), findsNothing);

      const here = GeoPoint(37.2450, 127.0801);
      location.emit(const LocationFix(point: here, accuracyMeters: 10));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byTooltip('현재 위치로'));

      expect(map.controller.movedTo, [here]);
    });

    testWidgets("② 출발점이 없으면 '현재 위치로' 버튼이 없다", (tester) async {
      final location = FakeLocationRepository(permission: LocationPermissionStatus.denied);
      final vm = DirectionsViewModel(
        directionsRepository: FakeDirectionsRepository(),
        locationRepository: location,
        destination: sampleCandidate(1),
      );
      addTearDown(vm.dispose);

      await pumpWith(tester, vm);
      location.emit(const LocationFix(point: GeoPoint(37.2450, 127.0801), accuracyMeters: 10));
      await tester.pump();
      await tester.pump();

      expect(find.byTooltip('현재 위치로'), findsNothing);
    });
  });
}
