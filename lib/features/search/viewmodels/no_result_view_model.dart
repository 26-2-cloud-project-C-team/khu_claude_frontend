import 'package:flutter/foundation.dart';

import '../data/search_repository.dart';
import '../models/condition_alternative.dart';
import '../models/search_condition.dart';
import '../models/search_result.dart';

/// 결과 없음(US-05). 조건 하나만 바꿔 실제로 검색해 보고, 1곳 이상인 대안만
/// 후보 수가 많은 순으로 최대 [maxAlternatives]개 보여준다.
class NoResultViewModel extends ChangeNotifier {
  NoResultViewModel({
    required this._repository,
    required this.condition,
    this.maxAlternatives = 3,
  });

  final SearchRepository _repository;
  final SearchCondition condition;
  final int maxAlternatives;

  List<ScoredAlternative> _alternatives = const [];
  int? _selectedIndex;
  bool _isLoading = false;

  List<ScoredAlternative> get alternatives => _alternatives;
  int? get selectedIndex => _selectedIndex;
  bool get isLoading => _isLoading;

  /// CTA 활성 여부. 선택 전에는 '후보 보기'로 비활성이다.
  bool get canSubmit => _selectedIndex != null;

  /// CTA 문구용 후보 수('8곳 보기'). 선택 전에는 null.
  int? get selectedCount => selected?.count;

  ScoredAlternative? get selected =>
      _selectedIndex == null ? null : _alternatives[_selectedIndex!];

  /// 고른 대안의 검색 결과. View는 SearchFlowViewModel.adopt 후 US-04로 보낸다.
  SearchResult? get selectedResult => selected?.result;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    final candidates = alternativesFor(condition);
    final scored = await Future.wait(candidates.map(_tryAlternative));
    final usable = scored.whereType<ScoredAlternative>().where((s) => s.count > 0).toList();
    // List.sort는 안정 정렬이 아니라서 생성 순서를 직접 동률 기준으로 쓴다.
    final order = {for (var i = 0; i < candidates.length; i++) candidates[i]: i};
    usable.sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : order[a.alternative]!.compareTo(order[b.alternative]!);
    });
    _alternatives = usable.take(maxAlternatives).toList();
    _selectedIndex = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<ScoredAlternative?> _tryAlternative(ConditionAlternative alternative) async {
    try {
      final result = await _repository.search(alternative.applyTo(condition));
      return ScoredAlternative(alternative: alternative, result: result);
    } on Exception {
      return null;
    }
  }

  /// 단일 선택. 같은 항목을 다시 눌러도 선택을 유지한다.
  void select(int index) {
    if (index < 0 || index >= _alternatives.length) return;
    _selectedIndex = index;
    notifyListeners();
  }
}
