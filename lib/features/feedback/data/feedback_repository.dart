import '../../../core/models/reinspection_category.dart';
import '../models/today_review.dart';

/// 이용 의견·재조사 요청 API(U4·U5·U6·U7). 기기 쿠키 세션 기준으로 서버가 중복을 막는다.
abstract class FeedbackRepository {
  /// U4. 오늘 이 기기에서 이 공간에 남긴 별점·후기. 없으면 null.
  Future<TodayReview?> fetchTodayReview(String spaceId);

  /// 별점(필수)과 후기(선택). 같은 날 다시 남기면 서버가 덮어쓴다.
  Future<void> submitReview({required String spaceId, required int rating, String? text});

  /// 처리 완료 전까지 기기당 1건.
  Future<void> requestReinspection({
    required String spaceId,
    required Set<ReinspectionCategory> categories,
    String? detail,
  });
}
