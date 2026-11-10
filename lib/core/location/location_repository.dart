import '../utils/geo.dart';

enum LocationPermissionStatus { granted, denied }

/// 위치 한 번 조회한 결과.
class LocationFix {
  const LocationFix({required this.point, required this.accuracyMeters});

  final GeoPoint point;

  /// 정확도 반경(m). US-01 A '정확도 ±20m'.
  final double accuracyMeters;
}

/// 브라우저 위치 API 접근. 검색(US-01 출발점)과 길찾기(US-06)가 함께 쓴다.
abstract class LocationRepository {
  /// 권한을 요청한다. 이미 정해져 있으면 바로 결과를 돌려준다.
  Future<LocationPermissionStatus> requestPermission();

  /// 현재 위치. 권한이 없거나 조회에 실패하면 null.
  Future<LocationFix?> currentFix();

  /// [interval]마다 현재 위치를 흘려보낸다. 조회에 실패한 회차는 건너뛴다.
  Stream<LocationFix> watch({Duration interval = const Duration(seconds: 10)});
}
