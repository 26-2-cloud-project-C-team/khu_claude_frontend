import 'package:flutter/foundation.dart';

import '../data/search_repository.dart';
import '../models/condition_alternative.dart';
import '../models/search_condition.dart';
import '../models/search_result.dart';

/// 결과 없음(US-05). 0곳 검색 결과에 U2가 함께 준 대안(후보 수가 많은 순, 최대 3개)을 보여주고,
/// 고른 대안의 조건으로 다시 검색한다.
class NoResultViewModel extends ChangeNotifier {
  NoResultViewModel({required this._repository, required this.result});

  final SearchRepository _repository;

  /// 0곳이었던 검색 결과.
  final SearchResult result;

  int? _selectedIndex;
  bool _isSearching = false;

  SearchCondition get condition => result.condition;
  List<ScoredAlternative> get alternatives => result.alternatives;
  int? get selectedIndex => _selectedIndex;
  bool get isSearching => _isSearching;

  /// CTA 활성 여부. 선택 전에는 '후보 보기'로 비활성이다.
  bool get canSubmit => _selectedIndex != null && !_isSearching;

  /// CTA 문구용 후보 수('8곳 보기'). 선택 전에는 null.
  int? get selectedCount => selected?.count;

  ScoredAlternative? get selected => _selectedIndex == null ? null : alternatives[_selectedIndex!];

  /// 단일 선택. 같은 항목을 다시 눌러도 선택을 유지한다.
  void select(int index) {
    if (index < 0 || index >= alternatives.length) return;
    _selectedIndex = index;
    notifyListeners();
  }

  /// CTA. 고른 대안의 조건을 바꾸지 않고, 처음 검색의 기준 시각 그대로 U2를 다시 부른다.
  /// 성공하면 결과를 돌려주고 View가 SearchFlowViewModel.adopt 후 US-04로 보낸다. 실패하면 null.
  Future<SearchResult?> adopt() async {
    final alternative = selected;
    if (alternative == null || _isSearching) return null;
    _isSearching = true;
    notifyListeners();
    try {
      return await _repository.search(alternative.condition, searchedAt: result.searchedAt);
    } on Exception {
      return null;
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }
}
