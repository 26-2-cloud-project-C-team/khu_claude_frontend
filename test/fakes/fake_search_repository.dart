import 'package:team_frontend/core/models/building.dart';
import 'package:team_frontend/features/search/data/search_repository.dart';
import 'package:team_frontend/features/search/models/candidate.dart';
import 'package:team_frontend/features/search/models/condition_alternative.dart';
import 'package:team_frontend/features/search/models/search_condition.dart';
import 'package:team_frontend/features/search/models/search_result.dart';

import 'sample_space.dart';

/// 정해진 건물·검색 결과·공간을 돌려준다. 호출 기록은 테스트에서 확인용으로 남긴다.
class FakeSearchRepository implements SearchRepository {
  FakeSearchRepository({
    this.buildings = const [],
    List<int> Function(SearchCondition condition)? onSearch,
    this.alternatives = const [],
    this.missingIds = const {},
    this.searchedAt,
    this.failBuildings = false,
    this.failSearch = false,
  }) : _onSearch = onSearch ?? ((_) => const []);

  List<Building> buildings;

  /// 조건마다 돌려줄 후보 공간 ID(1위부터). 상세는 [sampleCandidate]로 채운다.
  final List<int> Function(SearchCondition) _onSearch;

  /// 결과가 0곳일 때 함께 줄 대안.
  List<ScoredAlternative> alternatives;

  /// U3가 404로 답할 공간.
  Set<String> missingIds;

  /// 서버가 적용했다고 돌려줄 검색 기준 시각.
  DateTime? searchedAt;
  bool failBuildings;
  bool failSearch;

  int buildingCalls = 0;
  final List<SearchCondition> searchCalls = [];
  final List<DateTime?> searchedAtCalls = [];
  final List<String> spaceCalls = [];

  @override
  Future<List<Building>> fetchBuildings() async {
    buildingCalls++;
    if (failBuildings) throw Exception('U1 실패');
    return buildings;
  }

  @override
  Future<SearchResult> search(SearchCondition condition, {DateTime? searchedAt}) async {
    searchCalls.add(condition);
    searchedAtCalls.add(searchedAt);
    if (failSearch) throw Exception('U2 실패');
    final candidates = [for (final id in _onSearch(condition)) sampleCandidate(id)];
    return SearchResult(
      condition: condition,
      candidates: candidates,
      alternatives: candidates.isEmpty ? alternatives : const [],
      searchedAt: searchedAt ?? this.searchedAt,
    );
  }

  @override
  Future<CandidateDetail?> fetchSpace(String spaceId) async {
    spaceCalls.add(spaceId);
    return missingIds.contains(spaceId) ? null : sampleCandidate(spaceId);
  }
}
