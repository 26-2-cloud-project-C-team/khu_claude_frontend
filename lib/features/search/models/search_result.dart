import 'candidate.dart';
import 'condition_alternative.dart';
import 'search_condition.dart';

/// U2 검색 결과. 전체 후보의 상세를 한 번에 받는다.
/// 순위는 검색할 때 한 번 정해지고 넘기는 동안 바뀌지 않으며, 이전 · 다음 후보는 추가 요청 없이 보여준다.
class SearchResult {
  const SearchResult({
    required this.condition,
    required this.candidates,
    this.alternatives = const [],
    this.searchedAt,
  });

  /// 이 결과를 만든 조건. 조건 요약 시트에 쓴다.
  final SearchCondition condition;

  /// 1위부터 순서대로.
  final List<CandidateDetail> candidates;

  /// 0곳일 때만 온다. 서버가 후보 수가 많은 순으로 최대 3개를 준다(US-05).
  final List<ScoredAlternative> alternatives;

  /// 서버가 적용한 검색 기준 시각. US-05 대안 재검색에 그대로 넘겨 후보 수가 어긋나지 않게 한다.
  final DateTime? searchedAt;

  int get count => candidates.length;
  bool get isEmpty => candidates.isEmpty;
}
