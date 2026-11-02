import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/location/location_repository.dart';
import 'package:team_frontend/core/utils/geo.dart';
import 'package:team_frontend/features/directions/models/directions_stage.dart';
import 'package:team_frontend/features/directions/models/walking_route.dart';
import 'package:team_frontend/features/directions/viewmodels/directions_view_model.dart';
import 'package:team_frontend/features/search/models/origin.dart';

import '../../../fakes/fake_directions_repository.dart';
import '../../../fakes/fake_location_repository.dart';
import '../../../fakes/sample_space.dart';

void main() {
  const destinationPoint = GeoPoint(37.2410, 127.0800);
  late FakeDirectionsRepository directions;
  late FakeLocationRepository location;
  late DirectionsViewModel vm;

  setUp(() {
    directions = FakeDirectionsRepository(
      route: const WalkingRoute(path: [], distanceMeters: 450, minutes: 6),
    );
    location = FakeLocationRepository();
    vm = DirectionsViewModel(
      directionsRepository: directions,
      locationRepository: location,
      origin: BuildingOrigin(engineering),
      destination: sampleCandidate(1, buildingLocation: destinationPoint),
    );
  });

  tearDown(() => vm.dispose());

  test('보행 경로를 받으면 그대로 쓴다', () async {
    await vm.start();

    expect(vm.route!.distanceMeters, 450);
    expect(vm.route!.isFallback, isFalse);
    expect(vm.stage, DirectionsStage.moving);
  });

  test('보행 경로가 실패하면 직선 경로로 대체한다', () async {
    directions.fail = true;

    await vm.start();

    expect(vm.route!.isFallback, isTrue);
    expect(vm.route!.path, [engineering.point, destinationPoint]);
  });

  test('목적 건물 30m 안에 들어오면 isApproaching이다', () async {
    await vm.start();
    expect(vm.isApproaching, isFalse);

    location.emit(const LocationFix(point: GeoPoint(37.2465, 127.0802), accuracyMeters: 10));
    await Future<void>.delayed(Duration.zero);
    expect(vm.isApproaching, isFalse);

    location.emit(const LocationFix(point: GeoPoint(37.24101, 127.08001), accuracyMeters: 10));
    await Future<void>.delayed(Duration.zero);
    expect(vm.isApproaching, isTrue);
  });

  test('건물 도착 → 이용 중으로 진행하고 위치 갱신을 멈춘다', () async {
    await vm.start();
    expect(location.hasListener, isTrue);

    vm.arriveAtBuilding();
    expect(vm.stage, DirectionsStage.inBuilding);

    vm.startUsing();
    expect(vm.stage, DirectionsStage.inUse);
    expect(location.hasListener, isFalse);
  });

  test('길 안내 없이 바로 이용하기는 이동 중에서 바로 이용 중으로 간다', () async {
    await vm.start();

    vm.startUsing();

    expect(vm.stage, DirectionsStage.inUse);
  });
}
