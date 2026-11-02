import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/location/location_repository.dart';
import 'package:team_frontend/core/models/purpose.dart';
import 'package:team_frontend/features/search/models/origin.dart';
import 'package:team_frontend/features/search/viewmodels/search_flow_view_model.dart';
import 'package:team_frontend/features/search/views/building_select_page.dart';

import '../../../fakes/fake_location_repository.dart';
import '../../../fakes/fake_search_repository.dart';
import '../../../fakes/sample_space.dart';

void main() {
  late SearchFlowViewModel vm;
  var selected = 0;

  setUp(() {
    vm = SearchFlowViewModel(
      searchRepository: FakeSearchRepository(
        buildings: const [lifeScience, engineering, centralLibrary],
      ),
      locationRepository: FakeLocationRepository(permission: LocationPermissionStatus.denied),
    )..startWithPurpose(Purpose.solo);
    selected = 0;
  });

  Future<void> pumpPage(WidgetTester tester, {required bool unavailable}) async {
    await tester.pumpWidget(MaterialApp(
      home: BuildingSelectPage(
        viewModel: vm,
        locationUnavailable: unavailable,
        onSelected: () => selected++,
        onLocated: () {},
        onBack: () {},
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('위치가 없으면 안내 줄과 그에 맞는 제목을 보여준다', (tester) async {
    await pumpPage(tester, unavailable: true);

    expect(find.text('어느 건물에서 출발하시나요?'), findsOneWidget);
    expect(find.text('위치 권한이 필요해요'), findsOneWidget);
  });

  testWidgets('다른 건물에서 출발이면 안내 줄이 없다', (tester) async {
    await pumpPage(tester, unavailable: false);

    expect(find.text('출발할 건물을 선택해주세요'), findsOneWidget);
    expect(find.text('위치 권한이 필요해요'), findsNothing);
  });

  testWidgets('입력하면 이름으로 거르고 지우면 전체로 돌아온다', (tester) async {
    await pumpPage(tester, unavailable: false);

    await tester.enterText(find.byType(TextField), '공학');
    await tester.pump();
    expect(find.text('공학관'), findsOneWidget);
    expect(find.text('생명과학대학관'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.text('생명과학대학관'), findsOneWidget);
  });

  testWidgets('행을 누르면 확인 없이 출발점이 된다', (tester) async {
    await pumpPage(tester, unavailable: false);

    await tester.tap(find.text('공학관'));

    expect(selected, 1);
    expect(vm.condition.origin, BuildingOrigin(engineering));
  });
}
