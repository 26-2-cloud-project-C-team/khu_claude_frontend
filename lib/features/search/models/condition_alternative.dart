import 'requirement.dart';
import 'search_condition.dart';

/// 결과가 0곳일 때 조건 하나만 바꾸는 대안(US-05). U2 `alternatives[].type`.
/// 대안은 서버가 만든다(필요 조건 1개 제거 → 인원 감소 → 필요 조건 전체 제거).
sealed class ConditionAlternative {
  const ConditionAlternative();

  String get label;
}

/// `DROP_REQUIREMENT`
class RemoveRequirement extends ConditionAlternative {
  const RemoveRequirement(this.requirement);

  final Requirement requirement;

  @override
  String get label => '${requirement.label} 조건 빼기';

  @override
  bool operator ==(Object other) => other is RemoveRequirement && other.requirement == requirement;

  @override
  int get hashCode => requirement.hashCode;
}

/// `DECREASE_HEADCOUNT`. 서버는 후보가 있는 가장 큰 인원을 고르므로 한 번에 여러 명이 줄 수 있다.
class DecreaseHeadcount extends ConditionAlternative {
  const DecreaseHeadcount(this.headcount);

  /// 이 대안으로 다시 찾을 때의 인원.
  final int headcount;

  @override
  String get label => '인원 $headcount명으로 줄이기';

  @override
  bool operator ==(Object other) => other is DecreaseHeadcount && other.headcount == headcount;

  @override
  int get hashCode => headcount.hashCode;
}

/// `CLEAR_REQUIREMENTS`
class ClearRequirements extends ConditionAlternative {
  const ClearRequirements();

  @override
  String get label => '필요 조건 모두 지우기';

  @override
  bool operator ==(Object other) => other is ClearRequirements;

  @override
  int get hashCode => (ClearRequirements).hashCode;
}

/// U2가 돌려준 대안 하나. 서버가 그 조건으로 미리 검색해 본 후보 수를 함께 준다.
class ScoredAlternative {
  const ScoredAlternative({
    required this.alternative,
    required this.condition,
    required this.count,
  });

  final ConditionAlternative alternative;

  /// 재검색에 쓸 조건(`alternatives[].query`). 바꾸지 않고 그대로 U2에 넘긴다.
  final SearchCondition condition;

  /// 이 조건으로 검색한 후보 수. 1 이상.
  final int count;
}
