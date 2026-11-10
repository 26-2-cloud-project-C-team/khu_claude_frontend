import '../../../core/models/reinspection_category.dart';
import '../../../core/network/api_client.dart';
import '../models/today_review.dart';
import 'feedback_repository.dart';

/// [FeedbackRepository]를 `/api/spaces/{id}/my-review`(U4 · U5) · `/my-reinspection`(U6)으로 구현한다.
/// 기기는 서버가 발급하는 세션 쿠키(`khu_sid`)로 구분하므로 클라이언트는 따로 보내지 않는다.
class FeedbackRepositoryImpl implements FeedbackRepository {
  FeedbackRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<TodayReview?> fetchTodayReview(String spaceId) async {
    final json = await _api.get('/api/spaces/$spaceId/my-review') as Map<String, dynamic>;
    final review = json['review'] as Map<String, dynamic>?;
    if (review == null) return null;
    return TodayReview(rating: review['rating'] as int, text: review['comment'] as String?);
  }

  @override
  Future<void> submitReview({required String spaceId, required int rating, String? text}) async {
    // 별점만 등록할 때도 comment를 null로 보내 전체 교체한다(PUT).
    await _api.put('/api/spaces/$spaceId/my-review', body: {'rating': rating, 'comment': text});
  }

  @override
  Future<void> requestReinspection({
    required String spaceId,
    required Set<ReinspectionCategory> categories,
    String? detail,
  }) async {
    await _api.put(
      '/api/spaces/$spaceId/my-reinspection',
      body: {
        'categories': [
          for (final c in ReinspectionCategory.values)
            if (categories.contains(c)) c.code,
        ],
        'detail': detail,
      },
    );
  }
}
