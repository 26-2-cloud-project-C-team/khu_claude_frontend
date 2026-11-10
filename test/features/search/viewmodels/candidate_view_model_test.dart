import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/features/search/models/search_condition.dart';
import 'package:team_frontend/features/search/models/search_result.dart';
import 'package:team_frontend/features/search/viewmodels/candidate_view_model.dart';

import '../../../fakes/fake_search_repository.dart';
import '../../../fakes/sample_space.dart';

SearchResult _result(List<int> ids) => SearchResult(
  condition: const SearchCondition(),
  candidates: [for (final id in ids) sampleCandidate(id)],
);

void main() {
  test('1위부터 보여주고 다음 미리보기를 바로 준다', () {
    final vm = CandidateViewModel(result: _result([1, 2, 3, 4, 5]));

    expect(vm.rank, 1);
    expect(vm.total, 5);
    expect(vm.current!.spaceId, '1');
    expect(vm.nextPreview!.spaceId, '2');
    expect(vm.hasPrevious, isFalse);
    expect(vm.isLoading, isFalse);
  });

  test('받아 둔 목록에서 앞뒤로 넘긴다', () {
    final vm = CandidateViewModel(result: _result([1, 2, 3]));

    vm.next();
    vm.next();
    expect(vm.rank, 3);
    expect(vm.current!.spaceId, '3');

    vm.previous();
    expect(vm.rank, 2);
    expect(vm.nextPreview!.spaceId, '3');
  });

  test('마지막 순위에서 next는 아무것도 하지 않고 isLast다', () {
    final vm = CandidateViewModel(result: _result([1, 2]));
    vm.next();

    vm.next();

    expect(vm.rank, 2);
    expect(vm.isLast, isTrue);
    expect(vm.hasNext, isFalse);
    expect(vm.nextPreview, isNull);
  });

  test('1위에서 previous는 아무것도 하지 않는다', () {
    final vm = CandidateViewModel(result: _result([1, 2]));

    vm.previous();

    expect(vm.rank, 1);
  });

  test('검색 결과로 만들면 load는 아무것도 부르지 않는다', () async {
    final repo = FakeSearchRepository();
    final vm = CandidateViewModel(result: _result([1]));

    await vm.load();

    expect(repo.spaceCalls, isEmpty);
    expect(vm.current!.spaceId, '1');
  });

  group('복구 상태(US-04 ③)', () {
    late FakeSearchRepository repo;

    setUp(() => repo = FakeSearchRepository());

    test('공간 하나만 U3로 한 번 불러 보여준다', () async {
      final vm = CandidateViewModel.restored(repository: repo, spaceId: '7');
      expect(vm.current, isNull);

      await vm.load();

      expect(vm.isRestored, isTrue);
      expect(repo.spaceCalls, ['7']);
      expect(vm.current!.spaceId, '7');
      expect(vm.hasPrevious, isFalse);
      expect(vm.hasNext, isFalse);
      expect(vm.isUnavailable, isFalse);
    });

    test('U3가 404면 볼 수 없는 공간이다', () async {
      repo.missingIds = {'7'};
      final vm = CandidateViewModel.restored(repository: repo, spaceId: '7');

      await vm.load();

      expect(vm.isUnavailable, isTrue);
      expect(vm.current, isNull);
    });

    test('불러오는 동안 isLoading이다', () async {
      final vm = CandidateViewModel.restored(repository: repo, spaceId: '7');
      final states = <bool>[];
      vm.addListener(() => states.add(vm.isLoading));

      await vm.load();

      expect(states, [true, false]);
    });
  });
}
