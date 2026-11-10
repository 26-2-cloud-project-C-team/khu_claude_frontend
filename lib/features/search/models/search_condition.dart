import 'package:flutter/foundation.dart';

import '../../../core/models/purpose.dart';
import 'origin.dart';
import 'requirement.dart';
import 'sort_key.dart';

/// 검색 조건 5단계. 진행 바 칸 순서와 같다.
enum SearchStep { origin, purpose, headcount, requirements, sort }

/// 이번 검색에만 쓰는 조건. 저장하지 않는다(US-01 Check Point).
@immutable
class SearchCondition {
  const SearchCondition({
    this.origin,
    this.purpose,
    this.headcount = minHeadcount,
    this.requirements = const {},
    this.sortKeys = const {},
  });

  static const int minHeadcount = 1;
  static const int maxHeadcount = 10;

  final Origin? origin;
  final Purpose? purpose;
  final int headcount;
  final Set<Requirement> requirements;

  /// 비어 있으면 서버가 '가까운 곳'만으로 정렬한다.
  final Set<SortKey> sortKeys;

  /// 검색을 실행할 수 있는지. 나머지 단계는 기본값이 있다.
  bool get isComplete => origin != null && purpose != null;

  SearchCondition copyWith({
    Origin? origin,
    Purpose? purpose,
    int? headcount,
    Set<Requirement>? requirements,
    Set<SortKey>? sortKeys,
  }) {
    return SearchCondition(
      origin: origin ?? this.origin,
      purpose: purpose ?? this.purpose,
      headcount: headcount ?? this.headcount,
      requirements: requirements ?? this.requirements,
      sortKeys: sortKeys ?? this.sortKeys,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SearchCondition &&
      other.origin == origin &&
      other.purpose == purpose &&
      other.headcount == headcount &&
      setEquals(other.requirements, requirements) &&
      setEquals(other.sortKeys, sortKeys);

  @override
  int get hashCode => Object.hash(
        origin,
        purpose,
        headcount,
        Object.hashAllUnordered(requirements),
        Object.hashAllUnordered(sortKeys),
      );
}
