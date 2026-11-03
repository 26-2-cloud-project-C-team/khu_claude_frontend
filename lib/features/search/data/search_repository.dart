import '../../../core/models/building.dart';
import '../models/candidate.dart';
import '../models/search_condition.dart';
import '../models/search_result.dart';

/// 사용자 탐색 API(U1·U2·U3).
abstract class SearchRepository {
  /// U1. 공개 공간이 1곳 이상 있는 건물, 가나다순.
  Future<List<Building>> fetchBuildings();

  /// U2. 조건에 맞는 공간을 순위대로, 상세와 함께 한 번에. 필터·점수·정렬은 서버가 한다.
  /// 0곳이면 대안을 함께 준다. US-05 대안 재검색에는 처음 검색의 [searchedAt]을 그대로 넘긴다.
  Future<SearchResult> search(SearchCondition condition, {DateTime? searchedAt});

  /// U3. 공간 하나. 비공개 · 삭제(404)면 null. 검색 결과 없이 복구할 때(US-04 ③)만 쓴다.
  Future<CandidateDetail?> fetchSpace(int spaceId);
}
