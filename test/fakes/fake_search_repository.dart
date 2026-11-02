import 'package:team_frontend/core/models/building.dart';
import 'package:team_frontend/features/search/data/search_repository.dart';
import 'package:team_frontend/features/search/models/candidate.dart';
import 'package:team_frontend/features/search/models/search_condition.dart';
import 'package:team_frontend/features/search/models/search_result.dart';

import 'sample_space.dart';

/// 정해진 건물·검색 결과·상세를 돌려준다. 호출 기록은 테스트에서 확인용으로 남긴다.
class FakeSearchRepository implements SearchRepository {
  FakeSearchRepository({
    this.buildings = const [],
    List<int> Function(SearchCondition condition)? onSearch,
    this.missingIds = const {},
    this.failBuildings = false,
    this.failSearch = false,
  }) : _onSearch = onSearch ?? ((_) => const []);

  List<Building> buildings;
  final List<int> Function(SearchCondition) _onSearch;

  /// 상세를 요청하면 missingIds로 돌려줄 공간.
  Set<int> missingIds;
  bool failBuildings;
  bool failSearch;

  final List<SearchCondition> searchCalls = [];
  final List<List<int>> detailCalls = [];

  @override
  Future<List<Building>> fetchBuildings() async {
    if (failBuildings) throw Exception('U1 실패');
    return buildings;
  }

  @override
  Future<SearchResult> search(SearchCondition condition) async {
    searchCalls.add(condition);
    if (failSearch) throw Exception('U2 실패');
    return SearchResult(condition: condition, rankedSpaceIds: _onSearch(condition));
  }

  @override
  Future<CandidateDetailsBatch> fetchDetails(List<int> spaceIds) async {
    detailCalls.add(spaceIds);
    return CandidateDetailsBatch(
      details: {
        for (final id in spaceIds)
          if (!missingIds.contains(id)) id: sampleCandidate(id),
      },
      missingIds: spaceIds.where(missingIds.contains).toSet(),
    );
  }
}
