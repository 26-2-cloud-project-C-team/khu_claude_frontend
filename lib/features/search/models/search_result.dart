import 'search_condition.dart';

/// U2 검색 결과. 순위는 검색할 때 한 번 정해지고 넘기는 동안 바뀌지 않는다.
class SearchResult {
  const SearchResult({required this.condition, required this.rankedSpaceIds});

  /// 이 결과를 만든 조건. 조건 요약 시트와 US-05 대안 계산에 쓴다.
  final SearchCondition condition;

  /// 1위부터 순서대로.
  final List<int> rankedSpaceIds;

  int get count => rankedSpaceIds.length;
  bool get isEmpty => rankedSpaceIds.isEmpty;
}
