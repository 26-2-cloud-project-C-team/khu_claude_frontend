import 'package:flutter/foundation.dart';

import '../data/search_repository.dart';
import '../models/candidate.dart';
import '../models/search_result.dart';

/// 후보 상세(US-04). U2가 한 번에 준 순위 목록을 한 곳씩 넘긴다.
/// 이전 · 다음 이동은 받아 둔 목록에서 바로 보여주고 다시 부르지 않는다.
class CandidateViewModel extends ChangeNotifier {
  CandidateViewModel({required SearchResult result})
    : _candidates = result.candidates,
      _repository = null,
      _restoreId = null,
      isRestored = false;

  /// US-04 ③ 복구 상태. 공유 링크 · 앱 다시 열기 · 검색 결과 없이 US-06에서 돌아왔을 때
  /// 검색 결과 없이 공간 하나만 U3로 한 번 불러 보여준다.
  CandidateViewModel.restored({required SearchRepository this._repository, required int spaceId})
    : _candidates = const [],
      _restoreId = spaceId,
      isRestored = true;

  final SearchRepository? _repository;
  final int? _restoreId;

  /// 검색 결과 없이 공간 하나만 복구했는지. View는 순위 · 조건 · 거리 · 다음 후보를 숨긴다.
  final bool isRestored;

  List<CandidateDetail> _candidates;
  int _index = 0;
  bool _isLoading = false;
  bool _unavailable = false;
  Object? _error;

  /// 전체 후보 수('/ 12곳').
  int get total => _candidates.length;

  /// 1부터 시작하는 순위.
  int get rank => _index + 1;
  bool get hasPrevious => _index > 0;
  bool get hasNext => _index < _candidates.length - 1;

  /// 마지막 순위면 미리보기 카드가 '마지막 후보예요'로 바뀐다.
  bool get isLast => _candidates.isNotEmpty && !hasNext;

  CandidateDetail? get current => _candidates.isEmpty ? null : _candidates[_index];
  CandidateDetail? get nextPreview => hasNext ? _candidates[_index + 1] : null;

  /// 복구 중 U3를 기다리는 동안.
  bool get isLoading => _isLoading;
  Object? get error => _error;

  /// 복구하려던 공간을 볼 수 없다(U3 404). View는 US-00으로 보내며 토스트를 띄운다.
  bool get isUnavailable => _unavailable;

  /// 복구 상태면 U3로 공간을 불러온다. 검색 결과로 만들었으면 할 일이 없다.
  Future<void> load() async {
    final repository = _repository;
    final id = _restoreId;
    if (repository == null || id == null || _isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final space = await repository.fetchSpace(id);
      if (space == null) {
        _unavailable = true;
      } else {
        _candidates = [space];
      }
    } on Exception catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 하단 미리보기 카드, ›, 왼쪽 스와이프.
  void next() {
    if (!hasNext) return;
    _index++;
    notifyListeners();
  }

  /// ‹, 오른쪽 스와이프.
  void previous() {
    if (!hasPrevious) return;
    _index--;
    notifyListeners();
  }
}
