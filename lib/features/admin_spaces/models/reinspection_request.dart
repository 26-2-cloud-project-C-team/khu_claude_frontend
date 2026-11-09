import '../../../core/models/reinspection_category.dart';

class ReinspectionRequest {
  ReinspectionRequest({
    required this.id,
    required this.message,
    required this.requestedAt,
    ReinspectionCategory? category,
    List<ReinspectionCategory>? categories,
    this.isResolved = false,
    this.resolvedAt,
  }) : categories = categories ?? [category ?? ReinspectionCategory.etc];

  final String id;
  final String message;
  final DateTime requestedAt;
  final List<ReinspectionCategory> categories;
  final bool isResolved;
  final DateTime? resolvedAt;

  /// 기존 UI 호환용 대표 카테고리. 서버가 여러 항목을 반환하면 첫 항목을 사용한다.
  ReinspectionCategory get category =>
      categories.isEmpty ? ReinspectionCategory.etc : categories.first;
}
