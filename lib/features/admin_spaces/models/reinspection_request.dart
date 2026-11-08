import '../../../core/models/reinspection_category.dart';

class ReinspectionRequest {
  const ReinspectionRequest({
    required this.id,
    required this.message,
    required this.requestedAt,
    this.category = ReinspectionCategory.etc,
    this.isResolved = false,
    this.resolvedAt,
  });

  final String id;
  final String message;
  final DateTime requestedAt;
  final ReinspectionCategory category;
  final bool isResolved;
  final DateTime? resolvedAt;
}
