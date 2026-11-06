import 'package:flutter/foundation.dart';

import '../../../core/models/rating.dart' as rating_rules;
import '../data/feedback_repository.dart';
import '../models/rating.dart' as rating_rules;

enum ReviewStep {
  /// A · 별점(필수)
  rating,

  /// B · 후기(선택)
  text,
}

/// 이용 의견(US-07 A·B). 닫으면 입력값을 버리므로 화면이 열릴 때마다 새로 만든다.
class ReviewViewModel extends ChangeNotifier {
  ReviewViewModel({required this._repository, required this.spaceId});

  final FeedbackRepository _repository;
  final int spaceId;

  ReviewStep _step = ReviewStep.rating;
  int? _rating;
  String _text = '';
  bool _hasSavedText = false;
  bool _isSubmitting = false;
  Object? _error;

  ReviewStep get step => _step;
  int? get rating => _rating;
  String get text => _text;
  bool get isSubmitting => _isSubmitting;
  Object? get error => _error;

  /// '후기 없이 별점만 등록'을 보여줄지. 오늘 남긴 후기가 있으면 모르게 지워지지 않도록 숨긴다.
  bool get canSubmitRatingOnly => !_hasSavedText;

  /// '4점 · 만족해요'의 문구 부분.
  String? get ratingLabel => _rating == null ? null : rating_rules.ratingLabel(_rating!);

  bool get canProceedFromRating => _rating != null;
  int get textLength => _text.length;
  bool get isTextValid => _text.length <= rating_rules.reviewMaxLength;

  /// 오늘 남긴 별점·후기가 있으면 채운 상태로 연다. 실패해도 빈 상태로 진행한다.
  Future<void> load() async {
    try {
      final today = await _repository.fetchTodayReview(spaceId);
      if (today == null) return;
      _rating ??= today.rating;
      if (today.hasText) {
        _hasSavedText = true;
        if (_text.isEmpty) _text = today.text!;
      }
      notifyListeners();
    } on Exception {
      // 미리 채우기는 보조 기능이라 무시한다.
    }
  }

  void selectRating(int value) {
    if (value < rating_rules.minRating || value > rating_rules.maxRating) return;
    _rating = value;
    notifyListeners();
  }

  /// A '다음'.
  void goToText() {
    if (!canProceedFromRating) return;
    _step = ReviewStep.text;
    notifyListeners();
  }

  /// B에서 뒤로. 별점은 유지한다.
  void backToRating() {
    _step = ReviewStep.rating;
    notifyListeners();
  }

  void updateText(String value) {
    _text = value;
    notifyListeners();
  }

  /// '등록하기'([includeText] true) 또는 '후기 없이 별점만 등록'.
  /// 성공하면 true를 돌려주고 View가 완료 화면(US-08 A)으로 보낸다.
  Future<bool> submit({required bool includeText}) async {
    final value = _rating;
    if (value == null || _isSubmitting) return false;
    if (!includeText && !canSubmitRatingOnly) return false;
    final trimmed = _text.trim();
    if (includeText && !isTextValid) return false;

    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.submitReview(
        spaceId: spaceId,
        rating: value,
        text: includeText && trimmed.isNotEmpty ? trimmed : null,
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
