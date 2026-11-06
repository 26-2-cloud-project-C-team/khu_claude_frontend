import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/features/search/models/condition_alternative.dart';
import 'package:team_frontend/features/search/models/requirement.dart';

void main() {
  test('문구는 화면 설계서 US-05와 같다', () {
    expect(const RemoveRequirement(Requirement.charging).label, '충전 가능 조건 빼기');
    expect(const RemoveRequirement(Requirement.quiet).label, '조용한 분위기 조건 빼기');
    expect(const ClearRequirements().label, '필요 조건 모두 지우기');
  });

  test('같은 종류의 대안은 같다', () {
    expect(const RemoveRequirement(Requirement.quiet), const RemoveRequirement(Requirement.quiet));
    expect(
      const RemoveRequirement(Requirement.quiet) == const RemoveRequirement(Requirement.charging),
      isFalse,
    );
    expect(const DecreaseHeadcount(), const DecreaseHeadcount());
  });
}
