import 'package:flutter/foundation.dart';

import '../data/feedback_repository.dart';
import '../models/rating.dart';
import '../../../core/models/reinspection_category.dart';

/// 재조사 요청(US-07 C).
class ReinspectionViewModel extends ChangeNotifier {
  ReinspectionViewModel({required this._repository, required this.spaceId});

  final FeedbackRepository _repository;
  final int spaceId;

  final Set<ReinspectionCategory> _categories = {};
  String _detail = '';
  bool _isSubmitting = false;
  Object? _error;

  Set<ReinspectionCategory> get categories => Set.unmodifiable(_categories);
  String get detail => _detail;
  bool get isSubmitting => _isSubmitting;
  Object? get error => _error;

  bool isSelected(ReinspectionCategory c) => _categories.contains(c);

  /// 항목 1개 이상 필수, 상세 내용은 선택이지만 300자 이하.
  bool get canSubmit =>
      _categories.isNotEmpty && _detail.length <= reinspectionDetailMaxLength && !_isSubmitting;

  void toggle(ReinspectionCategory c) {
    if (!_categories.remove(c)) _categories.add(c);
    notifyListeners();
  }

  void updateDetail(String value) {
    _detail = value;
    notifyListeners();
  }

  /// '요청 보내기'. 성공하면 View가 완료 화면(US-08 B)으로 보낸다.
  Future<bool> submit() async {
    if (!canSubmit) return false;
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      final trimmed = _detail.trim();
      await _repository.requestReinspection(
        spaceId: spaceId,
        categories: {..._categories},
        detail: trimmed.isEmpty ? null : trimmed,
      );
      return true;
    } on Exception catch (e) {
      _error = e;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
