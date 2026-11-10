import 'package:team_frontend/features/feedback/data/feedback_repository.dart';
import 'package:team_frontend/core/models/reinspection_category.dart';
import 'package:team_frontend/features/feedback/models/today_review.dart';

class SubmittedReview {
  SubmittedReview(this.spaceId, this.rating, this.text);
  final String spaceId;
  final int rating;
  final String? text;
}

class SubmittedReinspection {
  SubmittedReinspection(this.spaceId, this.categories, this.detail);
  final String spaceId;
  final Set<ReinspectionCategory> categories;
  final String? detail;
}

class FakeFeedbackRepository implements FeedbackRepository {
  FakeFeedbackRepository({this.todayReview, this.fail = false});

  TodayReview? todayReview;
  bool fail;
  final List<SubmittedReview> reviews = [];
  final List<SubmittedReinspection> reinspections = [];

  @override
  Future<TodayReview?> fetchTodayReview(String spaceId) async => todayReview;

  @override
  Future<void> submitReview({required String spaceId, required int rating, String? text}) async {
    if (fail) throw Exception('의견 등록 실패');
    reviews.add(SubmittedReview(spaceId, rating, text));
  }

  @override
  Future<void> requestReinspection({
    required String spaceId,
    required Set<ReinspectionCategory> categories,
    String? detail,
  }) async {
    if (fail) throw Exception('재조사 요청 실패');
    reinspections.add(SubmittedReinspection(spaceId, categories, detail));
  }
}
