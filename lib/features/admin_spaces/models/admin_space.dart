class AdminSpace {
  const AdminSpace({
    required this.id,
    required this.name,
    required this.location,
    required this.updatedAt,
    required this.isPublic,
    this.reinspectionRequestCount = 0,
    this.buildingId,
    this.buildingName,
    this.floor,
    this.locationDetail,
    this.purposes = const [],
    this.isStale = false,
  });

  final String id;
  final String name;
  final String location;
  final DateTime updatedAt;
  final bool isPublic;
  final int reinspectionRequestCount;

  /// API 수정 요청에서 기존 위치 정보를 보존하기 위한 서버 원본 필드.
  final String? buildingId;
  final String? buildingName;
  final int? floor;
  final String? locationDetail;
  final List<String> purposes;
  final bool isStale;

  bool get hasReinspectionRequest => reinspectionRequestCount > 0;

  AdminSpace copyWith({
    String? name,
    String? location,
    DateTime? updatedAt,
    bool? isPublic,
    int? reinspectionRequestCount,
    String? buildingId,
    String? buildingName,
    int? floor,
    String? locationDetail,
    List<String>? purposes,
    bool? isStale,
  }) {
    return AdminSpace(
      id: id,
      name: name ?? this.name,
      location: location ?? this.location,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublic: isPublic ?? this.isPublic,
      reinspectionRequestCount:
          reinspectionRequestCount ?? this.reinspectionRequestCount,
      buildingId: buildingId ?? this.buildingId,
      buildingName: buildingName ?? this.buildingName,
      floor: floor ?? this.floor,
      locationDetail: locationDetail ?? this.locationDetail,
      purposes: purposes ?? this.purposes,
      isStale: isStale ?? this.isStale,
    );
  }
}
