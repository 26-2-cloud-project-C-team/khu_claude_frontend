import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/features/search/models/search_condition.dart';
import 'package:team_frontend/features/search/models/search_result.dart';
import 'package:team_frontend/features/search/viewmodels/candidate_view_model.dart';
import 'package:team_frontend/features/search/views/candidate_page.dart';

import '../../../fakes/fake_search_repository.dart';

void main() {
  Future<CandidateViewModel> pumpPage(WidgetTester tester, List<int> ids,
      {VoidCallback? onEmpty, ValueChanged<int>? onGo}) async {
    final vm = CandidateViewModel(
      repository: FakeSearchRepository(),
      result: SearchResult(condition: const SearchCondition(), rankedSpaceIds: ids),
    );
    await tester.pumpWidget(MaterialApp(
      home: CandidatePage(
        viewModel: vm,
        condition: const SearchCondition(),
        onClose: () {},
        onEditStep: (_) {},
        onGo: (c) => onGo?.call(c.spaceId),
        onEmpty: onEmpty ?? () {},
        onOpenPhoto: (_, _) {},
      ),
    ));
    await tester.pumpAndSettle();
    return vm;
  }

  testWidgets('1위부터 보여주고 미리보기 카드로 넘긴다', (tester) async {
    await pumpPage(tester, [1, 2, 3]);

    expect(find.text('1위'), findsOneWidget);
    expect(find.text('공간 1'), findsOneWidget);
    expect(find.text('다음 후보 · 2위'), findsOneWidget);

    await tester.tap(find.text('다음 후보 · 2위'));
    await tester.pumpAndSettle();

    expect(find.text('2위'), findsOneWidget);
    expect(find.text('공간 2'), findsOneWidget);
  });

  testWidgets('마지막 순위면 마지막 후보 카드를 보여준다', (tester) async {
    await pumpPage(tester, [1]);

    expect(find.text('마지막 후보예요'), findsOneWidget);
  });

  testWidgets('여기로 갈게요는 현재 후보를 넘긴다', (tester) async {
    int? went;
    await pumpPage(tester, [1, 2], onGo: (id) => went = id);

    await tester.tap(find.text('여기로 갈게요'));

    expect(went, 1);
  });
}
