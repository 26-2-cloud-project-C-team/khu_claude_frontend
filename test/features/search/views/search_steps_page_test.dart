import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/location/location_repository.dart';
import 'package:team_frontend/core/models/purpose.dart';
import 'package:team_frontend/features/search/models/search_condition.dart';
import 'package:team_frontend/features/search/models/search_result.dart';
import 'package:team_frontend/features/search/viewmodels/search_flow_view_model.dart';
import 'package:team_frontend/features/search/views/search_steps_page.dart';

import '../../../fakes/fake_location_repository.dart';
import '../../../fakes/fake_search_repository.dart';
import '../../../fakes/sample_space.dart';

void main() {
  late FakeLocationRepository location;
  late SearchFlowViewModel vm;
  bool? chooseBuildingUnavailable;
  SearchResult? searched;
  var exited = 0;

  setUp(() {
    location = FakeLocationRepository(
      fix: LocationFix(point: engineering.point, accuracyMeters: 20),
    );
    vm = SearchFlowViewModel(
      searchRepository: FakeSearchRepository(
        buildings: const [engineering, centralLibrary],
        onSearch: (_) => [1, 2],
      ),
      locationRepository: location,
    )..startWithPurpose(Purpose.solo);
    chooseBuildingUnavailable = null;
    searched = null;
    exited = 0;
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchStepsPage(
          viewModel: vm,
          onExit: () => exited++,
          onChooseBuilding: ({required bool locationUnavailable}) =>
              chooseBuildingUnavailable = locationUnavailable,
          onSearched: (r) => searched = r,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  FilledButton cta(WidgetTester tester) => tester.widget<FilledButton>(find.byType(FilledButton));

  testWidgets('위치를 얻으면 가장 가까운 건물 카드를 보여준다', (tester) async {
    await pumpPage(tester);

    expect(find.text('현재 위치에서 출발할까요?'), findsOneWidget);
    expect(find.text('공학관 앞 · 정확도 ±20m'), findsOneWidget);
    expect(cta(tester).onPressed, isNotNull);
  });

  testWidgets('위치를 못 가져오면 바로 US-03으로 보낸다', (tester) async {
    location.permission = LocationPermissionStatus.denied;

    await pumpPage(tester);

    expect(chooseBuildingUnavailable, isTrue);
  });

  testWidgets('다른 건물에서 출발할래요는 위치 있음 상태로 US-03을 연다', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('다른 건물에서 출발할래요'));

    expect(chooseBuildingUnavailable, isFalse);
  });

  testWidgets('목적 단계를 건너뛰고 인원 단계로 간다', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('이 위치에서 시작'));
    await tester.pumpAndSettle();

    expect(find.text('몇 명이 이용하나요?'), findsOneWidget);
    await tester.tap(find.byTooltip('인원 늘리기'));
    await tester.pump();
    expect(find.text('2명'), findsOneWidget);
  });

  testWidgets('정렬 단계에서 공간 찾기를 누르면 결과를 넘긴다', (tester) async {
    await pumpPage(tester);
    vm
      ..next()
      ..next()
      ..next();
    await tester.pumpAndSettle();
    expect(vm.step, SearchStep.sort);

    await tester.tap(find.text('공간 찾기'));
    await tester.pumpAndSettle();

    expect(searched!.candidates.map((c) => c.spaceId), [1, 2]);
  });

  testWidgets('첫 단계에서 뒤로 가면 퍼널을 닫는다', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byTooltip('뒤로'));

    expect(exited, 1);
  });
}
