// TODO(A-10): 건물 모델 작업(docs/tasks/platform/10)이 들어오면 그쪽 정의로 바꾸고 이 파일을 지운다.
import '../utils/geo.dart';

/// 캠퍼스 건물. API 명세 3.1 Building.
class Building {
  const Building({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
  });

  final int id;

  /// 캠퍼스맵 공식 표기. 예: 중앙도서관(대학본부)
  final String name;
  final double lat;
  final double lng;

  GeoPoint get point => GeoPoint(lat, lng);

  @override
  bool operator ==(Object other) => other is Building && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
