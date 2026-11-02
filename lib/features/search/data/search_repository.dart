import '../../../core/models/building.dart';
import '../models/candidate.dart';
import '../models/search_condition.dart';
import '../models/search_result.dart';

/// 사용자 탐색 API(U1·U2·U3).
abstract class SearchRepository {
  /// U1. 공개 공간이 1곳 이상 있는 건물, 가나다순.
  Future<List<Building>> fetchBuildings();

  /// U2. 조건에 맞는 공간을 순위대로. 필터·점수·정렬은 서버가 한다.
  Future<SearchResult> search(SearchCondition condition);

  /// U3. 요청한 공간의 상세. 없어진 공간은 [CandidateDetailsBatch.missingIds]로 온다.
  Future<CandidateDetailsBatch> fetchDetails(List<int> spaceIds);
}
