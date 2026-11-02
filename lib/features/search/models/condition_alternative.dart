import 'requirement.dart';
import 'search_condition.dart';
import 'search_result.dart';

/// 결과가 0곳일 때 조건 하나만 바꾸는 대안(US-05).
sealed class ConditionAlternative {
  const ConditionAlternative();

  SearchCondition applyTo(SearchCondition condition);

  String get label;
}

class RemoveRequirement extends ConditionAlternative {
  const RemoveRequirement(this.requirement);

  final Requirement requirement;

  @override
  SearchCondition applyTo(SearchCondition c) =>
      c.copyWith(requirements: {...c.requirements}..remove(requirement));

  @override
  String get label => '${requirement.label} 조건 빼기';

  @override
  bool operator ==(Object other) =>
      other is RemoveRequirement && other.requirement == requirement;

  @override
  int get hashCode => requirement.hashCode;
}

class DecreaseHeadcount extends ConditionAlternative {
  const DecreaseHeadcount();

  @override
  SearchCondition applyTo(SearchCondition c) =>
      c.copyWith(headcount: c.headcount - 1);

  @override
  String get label => '인원 1명 줄이기';

  @override
  bool operator ==(Object other) => other is DecreaseHeadcount;

  @override
  int get hashCode => (DecreaseHeadcount).hashCode;
}

class ClearRequirements extends ConditionAlternative {
  const ClearRequirements();

  @override
  SearchCondition applyTo(SearchCondition c) => c.copyWith(requirements: const {});

  @override
  String get label => '필요 조건 모두 지우기';

  @override
  bool operator ==(Object other) => other is ClearRequirements;

  @override
  int get hashCode => (ClearRequirements).hashCode;
}

/// 시도해볼 대안을 생성 순서대로 돌려준다.
/// 순서: 필요 조건 1개 제거 → 인원 1명 감소 → 필요 조건 전체 제거(US-05 Check Point).
/// 필요 조건이 1개뿐이면 '전체 제거'는 '1개 제거'와 같아서 넣지 않는다.
List<ConditionAlternative> alternativesFor(SearchCondition condition) {
  return [
    for (final r in Requirement.values)
      if (condition.requirements.contains(r)) RemoveRequirement(r),
    if (condition.headcount > SearchCondition.minHeadcount) const DecreaseHeadcount(),
    if (condition.requirements.length >= 2) const ClearRequirements(),
  ];
}

/// 실제로 검색해 본 대안과 그 결과.
class ScoredAlternative {
  const ScoredAlternative({required this.alternative, required this.result});

  final ConditionAlternative alternative;
  final SearchResult result;

  int get count => result.count;
}
