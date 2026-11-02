import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/features/directions/models/walking_route.dart';
import 'package:team_frontend/features/directions/viewmodels/directions_view_model.dart';
import 'package:team_frontend/features/directions/views/directions_page.dart';
import 'package:team_frontend/features/search/models/origin.dart';

import '../../../fakes/fake_directions_repository.dart';
import '../../../fakes/fake_location_repository.dart';
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
    await tester.pumpWidget(MaterialApp(
      home: DirectionsPage(
        viewModel: vm,
        onReview: () => reviews++,
        onReinspect: () {},
        onClose: () {},
      ),
    ));
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
}
