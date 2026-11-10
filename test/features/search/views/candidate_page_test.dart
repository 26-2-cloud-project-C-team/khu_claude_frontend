import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/features/search/models/search_condition.dart';
import 'package:team_frontend/features/search/models/search_result.dart';
import 'package:team_frontend/features/search/viewmodels/candidate_view_model.dart';
import 'package:team_frontend/features/search/views/candidate_page.dart';

import '../../../helpers/pump_test_app.dart';
import '../../../fakes/fake_search_repository.dart';
import '../../../fakes/sample_space.dart';

void main() {
  Future<CandidateViewModel> pumpPage(
    WidgetTester tester,
    List<int> ids, {
    ValueChanged<String>? onGo,
  }) async {
    final vm = CandidateViewModel(
      result: SearchResult(
        condition: const SearchCondition(),
        candidates: [for (final id in ids) sampleCandidate(id)],
      ),
    );
    await tester.pumpTestApp(
      CandidatePage(
        viewModel: vm,
        condition: const SearchCondition(),
        onClose: () {},
        onEditStep: (_) {},
        onGo: (c) => onGo?.call(c.spaceId),
        onOpenPhoto: (_, _) {},
      ),
    );
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
    String? went;
    await pumpPage(tester, [1, 2], onGo: (id) => went = id);

    await tester.tap(find.text('여기로 갈게요'));

    expect(went, '1');
  });

  group('복구 상태(US-04 ③)', () {
    Future<void> pumpRestored(
      WidgetTester tester, {
      Set<String> missingIds = const {},
      VoidCallback? onClose,
      VoidCallback? onUnavailable,
      ValueChanged<String>? onGo,
    }) async {
      final vm = CandidateViewModel.restored(
        repository: FakeSearchRepository(missingIds: missingIds),
        spaceId: '7',
      );
      await tester.pumpTestApp(
        CandidatePage.restored(
          viewModel: vm,
          onClose: onClose ?? () {},
          onGo: (c) => onGo?.call(c.spaceId),
          onUnavailable: onUnavailable ?? () {},
          onOpenPhoto: (_, _) {},
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('검색 결과에서 오는 값은 숨기고 안내 띠를 보여준다', (tester) async {
      await pumpRestored(tester);

      expect(find.text('공간 7'), findsOneWidget);
      expect(find.text('검색 조건이 사라져서 공간 정보만 보여 드려요'), findsOneWidget);
      expect(find.text('처음부터 다시 찾기'), findsOneWidget);
      expect(find.text('중앙도서관(대학본부)'), findsOneWidget);
      expect(find.textContaining('도보'), findsNothing);
      expect(find.text('조건'), findsNothing);
      expect(find.byTooltip('이전 후보'), findsNothing);
      expect(find.textContaining('다음 후보'), findsNothing);
      expect(find.text('마지막 후보예요'), findsNothing);
      expect(find.text('여기로 갈게요'), findsOneWidget);
    });

    testWidgets('처음부터 다시 찾기는 닫기와 같다', (tester) async {
      var closed = 0;
      await pumpRestored(tester, onClose: () => closed++);

      await tester.tap(find.text('처음부터 다시 찾기'));

      expect(closed, 1);
    });

    testWidgets('여기로 갈게요는 복구한 공간을 넘긴다', (tester) async {
      String? went;
      await pumpRestored(tester, onGo: (id) => went = id);

      await tester.tap(find.text('여기로 갈게요'));

      expect(went, '7');
    });

    testWidgets('볼 수 없는 공간이면 알린다', (tester) async {
      var unavailable = 0;
      await pumpRestored(tester, missingIds: {'7'}, onUnavailable: () => unavailable++);

      expect(unavailable, 1);
    });
  });
}
