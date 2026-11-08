class AdminSpace {
  const AdminSpace({
    required this.id,
    required this.name,
    required this.location,
    required this.updatedAt,
    required this.isPublic,
    this.reinspectionRequestCount = 0,
  });

  final String id;
  final String name;
  final String location;
  final DateTime updatedAt;
  final bool isPublic;
  final int reinspectionRequestCount;

  bool get hasReinspectionRequest => reinspectionRequestCount > 0;
}
