import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/features/feedback/models/reinspection_category.dart';
import 'package:team_frontend/features/feedback/viewmodels/reinspection_view_model.dart';

import '../../../fakes/fake_feedback_repository.dart';

void main() {
  late FakeFeedbackRepository repo;
  late ReinspectionViewModel vm;

  setUp(() {
    repo = FakeFeedbackRepository();
    vm = ReinspectionViewModel(repository: repo, spaceId: 7);
  });

  test('항목을 1개 이상 골라야 보낼 수 있다', () {
    expect(vm.canSubmit, isFalse);

    vm.toggle(ReinspectionCategory.hours);

    expect(vm.canSubmit, isTrue);
  });

  test('다시 누르면 선택이 풀린다', () {
    vm.toggle(ReinspectionCategory.hours);
    vm.toggle(ReinspectionCategory.hours);

    expect(vm.categories, isEmpty);
  });

  test('상세 내용이 300자를 넘으면 보낼 수 없다', () {
    vm.toggle(ReinspectionCategory.etc);
    vm.updateDetail('가' * 301);

    expect(vm.canSubmit, isFalse);
  });

  test('보내면 고른 항목과 다듬은 상세 내용이 간다', () async {
    vm.toggle(ReinspectionCategory.hours);
    vm.toggle(ReinspectionCategory.facility);
    vm.updateDetail('   ');

    final ok = await vm.submit();

    expect(ok, isTrue);
    final sent = repo.reinspections.single;
    expect(sent.spaceId, 7);
    expect(sent.categories, {ReinspectionCategory.hours, ReinspectionCategory.facility});
    expect(sent.detail, isNull);
  });
}
