import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/features/feedback/viewmodels/review_view_model.dart';

import '../../../fakes/fake_feedback_repository.dart';

void main() {
  late FakeFeedbackRepository repo;
  late ReviewViewModel vm;

  setUp(() {
    repo = FakeFeedbackRepository();
    vm = ReviewViewModel(repository: repo, spaceId: 7);
  });

  test('별점을 고르기 전에는 다음으로 갈 수 없다', () {
    vm.goToText();

    expect(vm.canProceedFromRating, isFalse);
    expect(vm.step, ReviewStep.rating);
  });

  test('별점을 고르면 문구가 나오고 후기 단계로 간다', () {
    vm.selectRating(4);
    vm.goToText();

    expect(vm.ratingLabel, '만족해요');
    expect(vm.step, ReviewStep.text);
  });

  test('범위 밖 별점은 무시한다', () {
    vm.selectRating(0);
    vm.selectRating(6);

    expect(vm.rating, isNull);
  });

  test('오늘 남긴 별점이 있으면 채워서 연다', () async {
    repo.todayRating = 3;

    await vm.load();

    expect(vm.rating, 3);
  });

  test('등록하기는 별점과 다듬은 후기를 보낸다', () async {
    vm.selectRating(5);
    vm.updateText('  조용해요  ');

    final ok = await vm.submit(includeText: true);

    expect(ok, isTrue);
    expect(repo.reviews.single.rating, 5);
    expect(repo.reviews.single.text, '조용해요');
  });

  test('별점만 등록은 후기를 보내지 않는다', () async {
    vm.selectRating(5);
    vm.updateText('조용해요');

    await vm.submit(includeText: false);

    expect(repo.reviews.single.text, isNull);
  });

  test('200자를 넘으면 등록하지 않는다', () async {
    vm.selectRating(5);
    vm.updateText('가' * 201);

    expect(vm.isTextValid, isFalse);
    expect(await vm.submit(includeText: true), isFalse);
    expect(repo.reviews, isEmpty);
  });

  test('실패하면 false와 오류를 남긴다', () async {
    repo.fail = true;
    vm.selectRating(5);

    expect(await vm.submit(includeText: false), isFalse);
    expect(vm.error, isNotNull);
    expect(vm.isSubmitting, isFalse);
  });
}
