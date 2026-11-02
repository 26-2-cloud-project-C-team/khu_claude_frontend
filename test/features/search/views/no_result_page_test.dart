import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/features/search/models/requirement.dart';
import 'package:team_frontend/features/search/models/search_condition.dart';
import 'package:team_frontend/features/search/viewmodels/no_result_view_model.dart';
import 'package:team_frontend/features/search/views/no_result_page.dart';

import '../../../fakes/fake_search_repository.dart';

void main() {
  testWidgets('대안을 고르기 전에는 비활성, 고르면 후보 수가 버튼에 나온다', (tester) async {
    final vm = NoResultViewModel(
      repository: FakeSearchRepository(onSearch: (c) => List.generate(8, (i) => i)),
      condition: const SearchCondition(requirements: {Requirement.quiet}),
    );
    await tester.pumpWidget(MaterialApp(
      home: NoResultPage(viewModel: vm, onAdopt: (_) {}, onRestart: () {}),
    ));
    await tester.pumpAndSettle();

    final cta = find.widgetWithText(FilledButton, '후보 보기');
    expect(tester.widget<FilledButton>(cta).onPressed, isNull);

    await tester.tap(find.text('조용한 분위기 조건 빼기'));
    await tester.pump();

    expect(find.widgetWithText(FilledButton, '8곳 보기'), findsOneWidget);
  });
}
