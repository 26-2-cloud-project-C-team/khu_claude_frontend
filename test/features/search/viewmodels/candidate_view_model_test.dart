import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/features/search/models/search_condition.dart';
import 'package:team_frontend/features/search/models/search_result.dart';
import 'package:team_frontend/features/search/viewmodels/candidate_view_model.dart';

import '../../../fakes/fake_search_repository.dart';

SearchResult _result(List<int> ids) =>
    SearchResult(condition: const SearchCondition(), rankedSpaceIds: ids);

void main() {
  late FakeSearchRepository repo;

  setUp(() => repo = FakeSearchRepository());

  test('처음에 1위부터 3개 묶음을 받는다', () async {
    final vm = CandidateViewModel(repository: repo, result: _result([1, 2, 3, 4, 5]));

    await vm.load();

    expect(repo.detailCalls, [
      [1, 2, 3],
    ]);
    expect(vm.rank, 1);
    expect(vm.total, 5);
    expect(vm.current!.spaceId, 1);
    expect(vm.nextPreview!.spaceId, 2);
    expect(vm.hasPrevious, isFalse);
  });

  test('받아 둔 범위 안에서 넘기면 다시 부르지 않는다', () async {
    final vm = CandidateViewModel(repository: repo, result: _result([1, 2, 3, 4, 5]));
    await vm.load();

    await vm.next();

    expect(vm.rank, 2);
    expect(vm.nextPreview!.spaceId, 3);
    expect(repo.detailCalls, hasLength(1));
  });

  test('미리보기가 비면 다음 묶음을 받는다', () async {
    final vm = CandidateViewModel(repository: repo, result: _result([1, 2, 3, 4, 5]));
    await vm.load();

    await vm.next();
    await vm.next();

    expect(vm.rank, 3);
    expect(repo.detailCalls.last, [4, 5]);
    expect(vm.nextPreview!.spaceId, 4);
  });

  test('missingIds는 순위에서 건너뛴다', () async {
    repo.missingIds = {2};
    final vm = CandidateViewModel(repository: repo, result: _result([1, 2, 3, 4]));

    await vm.load();

    expect(vm.total, 3);
    expect(vm.current!.spaceId, 1);
    expect(vm.nextPreview!.spaceId, 3);
  });

  test('묶음 전체가 사라지면 다음 묶음을 이어서 받는다', () async {
    repo.missingIds = {2, 3, 4};
    final vm = CandidateViewModel(repository: repo, result: _result([1, 2, 3, 4, 5]));

    await vm.load();

    expect(vm.total, 2);
    expect(vm.nextPreview!.spaceId, 5);
  });

  test('모두 사라지면 isEmpty다 (View가 US-05로 보낸다)', () async {
    repo.missingIds = {1, 2};
    final vm = CandidateViewModel(repository: repo, result: _result([1, 2]));

    await vm.load();

    expect(vm.isEmpty, isTrue);
    expect(vm.current, isNull);
  });

  test('마지막 순위에서 next는 아무것도 하지 않고 isLast다', () async {
    final vm = CandidateViewModel(repository: repo, result: _result([1, 2]));
    await vm.load();
    await vm.next();

    await vm.next();

    expect(vm.rank, 2);
    expect(vm.isLast, isTrue);
    expect(vm.hasNext, isFalse);
  });

  test('이전으로 돌아가도 다시 부르지 않는다', () async {
    final vm = CandidateViewModel(repository: repo, result: _result([1, 2, 3]));
    await vm.load();
    await vm.next();

    await vm.previous();

    expect(vm.rank, 1);
    expect(repo.detailCalls, hasLength(1));
  });

  group('복구 상태(US-04 ③)', () {
    test('공간 하나만 U3로 한 번 불러 보여준다', () async {
      final vm = CandidateViewModel.restored(repository: repo, spaceId: 7);

      await vm.load();

      expect(vm.isRestored, isTrue);
      expect(repo.detailCalls, [
        [7],
      ]);
      expect(vm.current!.spaceId, 7);
      expect(vm.hasPrevious, isFalse);
      expect(vm.hasNext, isFalse);
      expect(vm.isUnavailable, isFalse);
    });

    test('U3가 공간을 돌려주지 않으면 볼 수 없는 공간이다', () async {
      repo.missingIds = {7};
      final vm = CandidateViewModel.restored(repository: repo, spaceId: 7);

      await vm.load();

      expect(vm.isUnavailable, isTrue);
    });

    test('검색 결과에서 후보가 모두 사라진 것은 볼 수 없는 공간이 아니다', () async {
      repo.missingIds = {1};
      final vm = CandidateViewModel(repository: repo, result: _result([1]));

      await vm.load();

      expect(vm.isEmpty, isTrue);
      expect(vm.isUnavailable, isFalse);
    });
  });
}
