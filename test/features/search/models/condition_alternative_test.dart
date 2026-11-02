import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/features/search/models/condition_alternative.dart';
import 'package:team_frontend/features/search/models/requirement.dart';
import 'package:team_frontend/features/search/models/search_condition.dart';

void main() {
  group('alternativesFor', () {
    test('필요 조건 1개씩 제거 → 인원 감소 → 전체 제거 순서다', () {
      const condition = SearchCondition(
        headcount: 3,
        requirements: {Requirement.charging, Requirement.quiet},
      );

      final alternatives = alternativesFor(condition);

      expect(alternatives, [
        const RemoveRequirement(Requirement.quiet),
        const RemoveRequirement(Requirement.charging),
        const DecreaseHeadcount(),
        const ClearRequirements(),
      ]);
    });

    test('필요 조건이 1개면 전체 제거는 중복이라 넣지 않는다', () {
      const condition = SearchCondition(requirements: {Requirement.quiet});

      expect(alternativesFor(condition), [const RemoveRequirement(Requirement.quiet)]);
    });

    test('바꿀 조건이 없으면 비어 있다', () {
      expect(alternativesFor(const SearchCondition()), isEmpty);
    });
  });

  group('applyTo', () {
    const base = SearchCondition(
      headcount: 4,
      requirements: {Requirement.quiet, Requirement.charging},
    );

    test('하나만 바꾼다', () {
      expect(
        const RemoveRequirement(Requirement.quiet).applyTo(base).requirements,
        {Requirement.charging},
      );
      expect(const DecreaseHeadcount().applyTo(base).headcount, 3);
      expect(const ClearRequirements().applyTo(base).requirements, isEmpty);
    });

    test('원래 조건은 바뀌지 않는다', () {
      const RemoveRequirement(Requirement.quiet).applyTo(base);

      expect(base.requirements, {Requirement.quiet, Requirement.charging});
    });

    test('문구는 화면 설계서 US-05와 같다', () {
      expect(const RemoveRequirement(Requirement.charging).label, '충전 가능 조건 빼기');
      expect(const ClearRequirements().label, '필요 조건 모두 지우기');
    });
  });
}
