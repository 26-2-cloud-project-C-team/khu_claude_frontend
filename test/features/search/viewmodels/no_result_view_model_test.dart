import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/features/search/models/condition_alternative.dart';
import 'package:team_frontend/features/search/models/requirement.dart';
import 'package:team_frontend/features/search/models/search_condition.dart';
import 'package:team_frontend/features/search/models/search_result.dart';
import 'package:team_frontend/features/search/viewmodels/no_result_view_model.dart';

import '../../../fakes/fake_search_repository.dart';

void main() {
  const condition = SearchCondition(
    headcount: 3,
    requirements: {Requirement.quiet, Requirement.charging},
  );
  final searchedAt = DateTime.utc(2026, 11, 1, 5, 20);

  final alternatives = [
    const ScoredAlternative(
      alternative: ClearRequirements(),
      condition: SearchCondition(headcount: 3),
      count: 12,
    ),
    const ScoredAlternative(
      alternative: RemoveRequirement(Requirement.quiet),
      condition: SearchCondition(headcount: 3, requirements: {Requirement.charging}),
      count: 8,
    ),
  ];

  SearchResult empty() => SearchResult(
    condition: condition,
    candidates: const [],
    alternatives: alternatives,
    searchedAt: searchedAt,
  );

  test('U2가 준 대안을 그 순서대로 보여준다', () {
    final vm = NoResultViewModel(repository: FakeSearchRepository(), result: empty());

    expect(vm.alternatives.map((a) => a.count), [12, 8]);
    expect(vm.alternatives.first.alternative, const ClearRequirements());
  });

  test('선택 전에는 비활성, 선택하면 후보 수를 준다', () {
    final vm = NoResultViewModel(repository: FakeSearchRepository(), result: empty());
    expect(vm.canSubmit, isFalse);
    expect(vm.selectedCount, isNull);

    vm.select(1);

    expect(vm.canSubmit, isTrue);
    expect(vm.selectedCount, 8);
  });

  test('범위 밖 선택은 무시한다', () {
    final vm = NoResultViewModel(repository: FakeSearchRepository(), result: empty());

    vm.select(5);

    expect(vm.selectedIndex, isNull);
  });

  test('고른 대안의 조건을 처음 검색의 기준 시각 그대로 다시 검색한다', () async {
    final repo = FakeSearchRepository(onSearch: (_) => [1, 2, 3]);
    final vm = NoResultViewModel(repository: repo, result: empty());
    vm.select(1);

    final result = await vm.adopt();

    expect(repo.searchCalls.single, alternatives[1].condition);
    expect(repo.searchedAtCalls.single, searchedAt);
    expect(result!.count, 3);
    expect(vm.isSearching, isFalse);
  });

  test('고르지 않았으면 검색하지 않는다', () async {
    final repo = FakeSearchRepository();
    final vm = NoResultViewModel(repository: repo, result: empty());

    expect(await vm.adopt(), isNull);
    expect(repo.searchCalls, isEmpty);
  });

  test('재검색이 실패하면 null을 돌려준다', () async {
    final repo = FakeSearchRepository(failSearch: true);
    final vm = NoResultViewModel(repository: repo, result: empty());
    vm.select(0);

    expect(await vm.adopt(), isNull);
    expect(vm.canSubmit, isTrue);
  });
}
