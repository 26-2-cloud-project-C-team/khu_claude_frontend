import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/widgets/app_button.dart';
import 'package:team_frontend/features/search/models/condition_alternative.dart';
import 'package:team_frontend/features/search/models/requirement.dart';
import 'package:team_frontend/features/search/models/search_condition.dart';
import 'package:team_frontend/features/search/models/search_result.dart';
import 'package:team_frontend/features/search/viewmodels/no_result_view_model.dart';
import 'package:team_frontend/features/search/views/no_result_page.dart';

import '../../../helpers/pump_test_app.dart';
import '../../../fakes/fake_search_repository.dart';

void main() {
  testWidgets('대안을 고르기 전에는 비활성, 고르면 후보 수가 버튼에 나오고 다시 검색한다', (tester) async {
    final repo = FakeSearchRepository(onSearch: (_) => List.generate(8, (i) => i + 1));
    final vm = NoResultViewModel(
      repository: repo,
      result: const SearchResult(
        condition: SearchCondition(requirements: {Requirement.quiet}),
        candidates: [],
        alternatives: [
          ScoredAlternative(
            alternative: RemoveRequirement(Requirement.quiet),
            condition: SearchCondition(),
            count: 8,
          ),
        ],
      ),
    );
    SearchResult? adopted;
    await tester.pumpTestApp(
      NoResultPage(viewModel: vm, onAdopt: (r) => adopted = r, onRestart: () {}),
    );
    await tester.pumpAndSettle();

    final cta = find.widgetWithText(AppButton, '후보 보기');
    expect(tester.widget<AppButton>(cta).onPressed, isNull);

    await tester.tap(find.text('조용한 분위기 조건 빼기'));
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, '8곳 보기'));
    await tester.pumpAndSettle();

    expect(adopted!.count, 8);
    expect(repo.searchCalls.single, const SearchCondition());
  });
}
