/// 오늘 이 기기에서 이 공간에 남긴 이용 의견(U4 복원값).
class TodayReview {
  const TodayReview({required this.rating, this.text});

  final int rating;

  /// 별점만 남겼으면 null.
  final String? text;

  /// 후기가 있으면 US-07 B에서 '후기 없이 별점만 등록'을 숨긴다.
  bool get hasText => text != null && text!.trim().isNotEmpty;
}
