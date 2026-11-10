import '../../../core/errors/app_exception.dart';
import '../../../core/models/building.dart';
import '../../../core/network/api_client.dart';
import '../models/candidate.dart';
import '../models/condition_alternative.dart';
import '../models/requirement.dart';
import '../models/search_condition.dart';
import '../models/search_result.dart';
import '../models/sort_key.dart';
import 'search_repository.dart';

/// [SearchRepository]를 `/api/buildings`(U1) · `/api/spaces/search`(U2) · `/api/spaces/{id}`(U3)로 구현한다.
class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<List<Building>> fetchBuildings() async {
    final json = await _api.get('/api/buildings') as Map<String, dynamic>;
    return [
      for (final b in json['buildings'] as List<dynamic>)
        Building.fromJson(b as Map<String, dynamic>),
    ];
  }

  @override
  Future<SearchResult> search(SearchCondition condition, {DateTime? searchedAt}) async {
    final origin = condition.origin;
    final purpose = condition.purpose;
    if (origin == null || purpose == null) {
      throw ArgumentError('출발점과 목적이 정해져야 검색할 수 있다');
    }
    final json = await _api.get(
      '/api/spaces/search',
      query: {
        'origin': origin.apiParam,
        'purpose': purpose.code,
        'headcount': condition.headcount,
        // 쉼표로 구분한다(style: form, explode: false). 비어 있으면 보내지 않는다.
        if (condition.requirements.isNotEmpty)
          'require': _codes(Requirement.values, condition.requirements, (r) => r.code),
        if (condition.sortKeys.isNotEmpty)
          'sort': _codes(SortKey.values, condition.sortKeys, (k) => k.code),
        if (searchedAt != null) 'searchedAt': formatKstDateTime(searchedAt),
      },
    ) as Map<String, dynamic>;

    return SearchResult(
      condition: condition,
      searchedAt: DateTime.parse(json['searchedAt'] as String),
      candidates: [
        for (final c in json['candidates'] as List<dynamic>)
          CandidateDetail.fromJson(c as Map<String, dynamic>),
      ],
      alternatives: [
        for (final a in json['alternatives'] as List<dynamic>)
          ?_alternative(condition, a as Map<String, dynamic>),
      ],
    );
  }

  @override
  Future<CandidateDetail?> fetchSpace(String spaceId) async {
    try {
      final json = await _api.get('/api/spaces/$spaceId') as Map<String, dynamic>;
      return CandidateDetail.fromJson(json);
    } on AppException catch (e) {
      // 비공개 · 삭제(404)와 UUID가 아닌 링크(400)는 모두 '볼 수 없는 공간'으로 다룬다.
      if (e.statusCode == 404 || e.statusCode == 400) return null;
      rethrow;
    }
  }

  /// `alternatives[]` 하나. 재검색 조건은 출발점과 목적을 그대로 두고 `query`의 인원 · 필요 조건 · 정렬로 바꾼다.
  /// 모르는 대안 종류는 건너뛴다.
  static ScoredAlternative? _alternative(SearchCondition base, Map<String, dynamic> json) {
    final query = json['query'] as Map<String, dynamic>;
    final alternative = switch (json['type']) {
      'DROP_REQUIREMENT' => switch (_requirement(json['requirement'] as String?)) {
        final r? => RemoveRequirement(r),
        null => null,
      },
      'DECREASE_HEADCOUNT' => const DecreaseHeadcount(),
      'CLEAR_REQUIREMENTS' => const ClearRequirements(),
      _ => null,
    };
    if (alternative == null) return null;
    return ScoredAlternative(
      alternative: alternative,
      count: json['count'] as int,
      condition: base.copyWith(
        headcount: query['headcount'] as int,
        requirements: {
          for (final code in query['require'] as List<dynamic>) ?_requirement(code as String),
        },
        sortKeys: {for (final code in query['sort'] as List<dynamic>) ?_sortKey(code as String)},
      ),
    );
  }

  static Requirement? _requirement(String? code) {
    for (final r in Requirement.values) {
      if (r.code == code) return r;
    }
    return null;
  }

  static SortKey? _sortKey(String code) {
    for (final k in SortKey.values) {
      if (k.code == code) return k;
    }
    return null;
  }

  /// 화면 순서대로 코드를 쉼표로 잇는다.
  static String _codes<T>(List<T> order, Set<T> selected, String Function(T) codeOf) => [
    for (final v in order)
      if (selected.contains(v)) codeOf(v),
  ].join(',');
}

/// `searchedAt` 쿼리 값. RFC 3339 KST(`2026-11-01T14:20:00+09:00`).
String formatKstDateTime(DateTime time) {
  final kst = time.toUtc().add(const Duration(hours: 9));
  String two(int v) => v.toString().padLeft(2, '0');
  return '${kst.year}-${two(kst.month)}-${two(kst.day)}'
      'T${two(kst.hour)}:${two(kst.minute)}:${two(kst.second)}+09:00';
}
