import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/models/purpose.dart';
import 'package:team_frontend/features/search/viewmodels/search_flow_view_model.dart';
import 'package:team_frontend/features/search/views/start_page.dart';

import '../../../fakes/fake_location_repository.dart';
import '../../../fakes/fake_search_repository.dart';

void main() {
  testWidgets('목적 타일을 누르면 그 목적으로 시작한다', (tester) async {
    final vm = SearchFlowViewModel(
      searchRepository: FakeSearchRepository(),
      locationRepository: FakeLocationRepository(),
    );
    var started = 0;
    await tester.pumpWidget(MaterialApp(
      home: StartPage(viewModel: vm, onStarted: () => started++),
    ));

    expect(find.text('어떤 공간을 찾아 드릴까요?'), findsOneWidget);
    await tester.tap(find.text('사담'));

    expect(started, 1);
    expect(vm.condition.purpose, Purpose.chat);
  });
}
