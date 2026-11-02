import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/features/search/models/condition_alternative.dart';
import 'package:team_frontend/features/search/models/requirement.dart';
import 'package:team_frontend/features/search/models/search_condition.dart';
import 'package:team_frontend/features/search/viewmodels/no_result_view_model.dart';

import '../../../fakes/fake_search_repository.dart';

void main() {
  const condition = SearchCondition(
    headcount: 3,
    requirements: {Requirement.quiet, Requirement.charging},
  );

  /// 조건에 따라 결과 수를 정해 둔다.
  FakeSearchRepository repoReturning(int Function(SearchCondition c) count) =>
      FakeSearchRepository(onSearch: (c) => List.generate(count(c), (i) => i + 1));

  test('후보 수가 많은 순으로 1곳 이상인 대안만 보여준다', () async {
    final repo = repoReturning((c) {
      if (c.requirements.isEmpty) return 12;
      if (c.requirements.length == 1 && c.requirements.contains(Requirement.quiet)) return 8;
      if (c.requirements.length == 1) return 5;
      return 0; // 인원 감소
    });
    final vm = NoResultViewModel(repository: repo, condition: condition);

    await vm.load();

    expect(vm.alternatives.map((a) => a.count), [12, 8, 5]);
    expect(vm.alternatives.first.alternative, const ClearRequirements());
  });

  test('최대 3개까지만 보여준다', () async {
    final vm = NoResultViewModel(repository: repoReturning((_) => 4), condition: condition);

    await vm.load();

    expect(vm.alternatives, hasLength(3));
  });

  test('후보 수가 같으면 생성 순서를 유지한다', () async {
    final vm = NoResultViewModel(repository: repoReturning((_) => 4), condition: condition);

    await vm.load();

    expect(vm.alternatives.map((a) => a.alternative), [
      const RemoveRequirement(Requirement.quiet),
      const RemoveRequirement(Requirement.charging),
      const DecreaseHeadcount(),
    ]);
  });

  test('선택 전에는 비활성, 선택하면 후보 수와 결과를 준다', () async {
    final vm = NoResultViewModel(
      repository: repoReturning((c) => c.requirements.isEmpty ? 12 : 3),
      condition: condition,
    );
    await vm.load();
    expect(vm.canSubmit, isFalse);
    expect(vm.selectedCount, isNull);

    vm.select(0);

    expect(vm.canSubmit, isTrue);
    expect(vm.selectedCount, 12);
    expect(vm.selectedResult!.condition.requirements, isEmpty);
  });

  test('검색이 실패한 대안은 빼고 나머지를 보여준다', () async {
    var calls = 0;
    final repo = FakeSearchRepository(onSearch: (_) {
      calls++;
      if (calls == 1) throw Exception('실패');
      return [1];
    });
    final vm = NoResultViewModel(repository: repo, condition: condition);

    await vm.load();

    expect(vm.alternatives, hasLength(3));
  });
}
