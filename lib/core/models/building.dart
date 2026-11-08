class Building {
  const Building({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.floorRange,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    final floorRange = json['floorRange'] as Map<String, dynamic>;
    return Building(
      id: json['id'] as String,
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      floorRange: FloorRange(
        min: floorRange['min'] as int,
        max: floorRange['max'] as int,
      ),
    );
  }

  final String id;

  /// 캠퍼스맵 공식 표기. 예: 중앙도서관(대학본부)
  final String name;
  final double lat;
  final double lng;
  final FloorRange floorRange;

  @override
  bool operator ==(Object other) => other is Building && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Building($id, $name)';
}

/// 건물의 층 범위. 지하가 있으면 [min]이 -1이고, 0층은 없다.
class FloorRange {
  const FloorRange({required this.min, required this.max});

  final int min;
  final int max;

  /// 아래층부터 차례로, 0층을 뺀 층 목록.
  List<int> get floors => [
    for (var floor = min; floor <= max; floor++)
      if (floor != 0) floor,
  ];
}
