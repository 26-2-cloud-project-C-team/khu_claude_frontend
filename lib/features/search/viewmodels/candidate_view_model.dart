import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../data/search_repository.dart';
import '../models/candidate.dart';
import '../models/search_result.dart';

/// 후보 상세(US-04). 받아 둔 순위 목록을 한 곳씩 넘긴다.
///
/// 현재 순위와 다음 미리보기 카드를 보여줄 수 있도록, 받지 않은 공간이 있으면
/// [batchSize]개씩 묶어 U3로 미리 받는다. U3가 missingIds로 돌려준 공간은 순위에서 뺀다.
class CandidateViewModel extends ChangeNotifier {
  CandidateViewModel({
    required this._repository,
    required SearchResult result,
    this.batchSize = 3,
  }) : _ids = [...result.rankedSpaceIds];

  final SearchRepository _repository;
  final int batchSize;
  final List<int> _ids;
  final Map<int, CandidateDetail> _details = {};

  int _index = 0;
  Future<void>? _inFlight;
  Object? _error;

  /// 지금까지 남은 후보 수('/ 12곳').
  int get total => _ids.length;

  /// 1부터 시작하는 순위.
  int get rank => _index + 1;
  bool get hasPrevious => _index > 0;
  bool get hasNext => _index < _ids.length - 1;

  /// 마지막 순위면 미리보기 카드가 '마지막 후보예요'로 바뀐다.
  bool get isLast => _ids.isNotEmpty && !hasNext;

  /// 받아 둔 공간이 모두 사라졌을 때. View는 US-05로 보낸다.
  bool get isEmpty => _ids.isEmpty;

  CandidateDetail? get current => isEmpty ? null : _details[_ids[_index]];
  CandidateDetail? get nextPreview => hasNext ? _details[_ids[_index + 1]] : null;

  bool get isLoading => _inFlight != null && current == null;
  Object? get error => _error;

  Future<void> load() => _ensureWindow();

  /// 하단 미리보기 카드, ›, 왼쪽 스와이프.
  Future<void> next() async {
    if (!hasNext) return;
    _index++;
    notifyListeners();
    await _ensureWindow();
  }

  /// ‹, 오른쪽 스와이프.
  Future<void> previous() async {
    if (!hasPrevious) return;
    _index--;
    notifyListeners();
    await _ensureWindow();
  }

  Future<void> retry() {
    _error = null;
    return _ensureWindow();
  }

  Future<void> _ensureWindow() async {
    final running = _inFlight;
    if (running != null) {
      await running;
      // 기다리는 동안 순위가 바뀌었을 수 있어 다시 확인한다.
      if (_needsFetch()) return _ensureWindow();
      return;
    }
    final future = _fill();
    _inFlight = future;
    notifyListeners();
    try {
      await future;
    } finally {
      _inFlight = null;
      notifyListeners();
    }
  }

  bool _needsFetch() => _missingInWindow().isNotEmpty;

  List<int> _missingInWindow() {
    final end = math.min(_index + 2, _ids.length);
    return [
      for (var i = _index; i < end; i++)
        if (!_details.containsKey(_ids[i])) _ids[i],
    ];
  }

  Future<void> _fill() async {
    while (true) {
      final missing = _missingInWindow();
      if (missing.isEmpty) return;

      final start = _ids.indexOf(missing.first);
      final batch = _ids
          .skip(start)
          .where((id) => !_details.containsKey(id))
          .take(batchSize)
          .toList();

      final CandidateDetailsBatch response;
      try {
        response = await _repository.fetchDetails(batch);
      } on Exception catch (e) {
        _error = e;
        return;
      }
      _error = null;
      _details.addAll(response.details);

      // 상세도 missingIds도 아닌 ID는 서버가 빠뜨린 것이다. 무한 반복을 막기 위해 함께 뺀다.
      final gone = {
        ...response.missingIds,
        for (final id in batch)
          if (!response.details.containsKey(id)) id,
      };
      // batch는 현재 순위 이후에서만 고르므로 앞쪽 순위는 영향을 받지 않는다.
      _ids.removeWhere(gone.contains);
      if (_index >= _ids.length) _index = math.max(0, _ids.length - 1);
    }
  }
}
