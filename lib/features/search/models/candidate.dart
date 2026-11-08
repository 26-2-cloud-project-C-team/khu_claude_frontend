import '../../../core/models/noise_level.dart';
import '../../../core/models/reinspection_category.dart';
import '../../../core/models/space_photo.dart';
import '../../../core/utils/geo.dart';

/// 최근 이용 의견 한 건(`recentReviews[]`).
class SpaceReview {
  const SpaceReview({required this.rating, required this.createdAt, this.text});

  factory SpaceReview.fromJson(Map<String, dynamic> json) => SpaceReview(
    rating: json['rating'] as int,
    text: json['comment'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  final int rating;
  final DateTime createdAt;

  /// 별점만 남긴 의견은 null.
  final String? text;
}

/// 처리 완료된 재조사 결과(`reinspectionResults[]`). US-04 이용 의견 영역의 Q&A.
class ReinspectionResult {
  const ReinspectionResult({
    required this.categories,
    required this.result,
    required this.resolvedAt,
  });

  factory ReinspectionResult.fromJson(Map<String, dynamic> json) => ReinspectionResult(
    categories: [
      for (final code in json['categories'] as List<dynamic>)
        ReinspectionCategory.fromCode(code as String),
    ],
    result: json['result'] as String,
    resolvedAt: DateTime.parse(json['resolvedAt'] as String),
  );

  final List<ReinspectionCategory> categories;
  final String result;
  final DateTime resolvedAt;
}

/// 후보 상세(US-04)에 필요한 공간 정보. U2 `candidates[]`, U3 응답.
class CandidateDetail {
  const CandidateDetail({
    required this.spaceId,
    required this.name,
    required this.buildingId,
    required this.buildingName,
    required this.buildingLocation,
    required this.floor,
    required this.locationGuide,
    required this.photos,
    required this.opensAt,
    required this.closesAt,
    required this.ratingAverage,
    required this.ratingCount,
    required this.tableCount,
    required this.maxPerTable,
    required this.chargeableTableCount,
    required this.chargeablePercent,
    required this.freeWifi,
    required this.noise,
    required this.isCafe,
    this.distanceMeters,
    this.walkMinutes,
    this.note,
    this.pros,
    this.cons,
    this.recentReviews = const [],
    this.results = const [],
  });

  /// U2 후보는 `distanceM` · `walkMin`이 있고, U3(복구)는 출발점이 없어 둘 다 없다.
  factory CandidateDetail.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>;
    final building = json['building'] as Map<String, dynamic>;
    final rules = json['rules'] as Map<String, dynamic>;
    final hours = rules['hours'] as Map<String, dynamic>;
    final facilities = json['facilities'] as Map<String, dynamic>;
    final impressions = json['impressions'] as Map<String, dynamic>;
    final rating = json['ratingSummary'] as Map<String, dynamic>;
    return CandidateDetail(
      spaceId: json['id'] as String,
      name: location['name'] as String,
      buildingId: building['id'] as String,
      buildingName: building['name'] as String,
      buildingLocation: GeoPoint(
        (building['lat'] as num).toDouble(),
        (building['lng'] as num).toDouble(),
      ),
      floor: location['floor'] as int,
      locationGuide: location['locationDetail'] as String,
      photos: SpacePhoto.listFromJson(json['photos'] as Map<String, dynamic>),
      distanceMeters: json['distanceM'] as int?,
      walkMinutes: json['walkMin'] as int?,
      opensAt: hours['open'] as String,
      closesAt: hours['close'] as String,
      ratingAverage: (rating['avg'] as num?)?.toDouble(),
      ratingCount: rating['count'] as int,
      tableCount: facilities['tableCount'] as int,
      maxPerTable: facilities['maxSeatsPerTable'] as int,
      chargeableTableCount: facilities['chargeableTables'] as int,
      chargeablePercent: json['chargeableRatio'] as int,
      freeWifi: facilities['freeWifi'] as bool,
      noise: NoiseLevel.fromCode(rules['noiseLevel'] as String),
      isCafe: rules['isCafe'] as bool,
      note: impressions['note'] as String?,
      pros: impressions['pros'] as String?,
      cons: impressions['cons'] as String?,
      recentReviews: [
        for (final r in json['recentReviews'] as List<dynamic>)
          SpaceReview.fromJson(r as Map<String, dynamic>),
      ],
      results: [
        for (final r in json['reinspectionResults'] as List<dynamic>)
          ReinspectionResult.fromJson(r as Map<String, dynamic>),
      ],
    );
  }

  final String spaceId;

  /// 예: 중앙도서관 4층 열람실
  final String name;

  /// 길찾기(U7)의 도착점 `building:{buildingId}`.
  final String buildingId;
  final String buildingName;

  /// 길찾기 목적지와 30m 도착 판정 기준.
  final GeoPoint buildingLocation;

  /// 지하 1층은 -1. 0층은 없다.
  final int floor;

  /// 예: 엘리베이터에서 내려 왼쪽 끝
  final String locationGuide;

  /// 입구 · 가는 길 · 내부 · 추가 사진 순서.
  final List<SpacePhoto> photos;

  /// 출발점에서의 직선거리(m)와 분속 70m 기준 도보 시간. 복구(U3)에서는 null.
  final int? distanceMeters;
  final int? walkMinutes;

  /// 오늘 이용 시간 'HH:mm'. 같으면 24시간 운영이다.
  final String opensAt;
  final String closesAt;

  /// 평가가 없으면 null.
  final double? ratingAverage;
  final int ratingCount;

  final int tableCount;
  final int maxPerTable;
  final int chargeableTableCount;

  /// '충전되는 테이블 80%'. 서버 계산값(`chargeableRatio`).
  final int chargeablePercent;
  final bool freeWifi;
  final NoiseLevel noise;
  final bool isCafe;

  /// 비고(출입·취식 규칙 등). 카페면 화면에서 앞에 '카페'를 붙인다.
  final String? note;
  final String? pros;
  final String? cons;
  final List<SpaceReview> recentReviews;
  final List<ReinspectionResult> results;

  /// '4층', '지하 1층'.
  String get floorLabel => floor < 0 ? '지하 ${-floor}층' : '$floor층';

  /// '지금 이용 가능' 배지. API에 따로 없어 이용 시간과 KST 현재 시각으로 판단한다.
  bool get availableNow => isOpenAt(DateTime.now());

  bool isOpenAt(DateTime time) {
    if (opensAt == closesAt) return true;
    final kst = time.toUtc().add(const Duration(hours: 9));
    final now = kst.hour * 60 + kst.minute;
    final open = _minutes(opensAt);
    final close = _minutes(closesAt);
    // 자정을 넘기는 시간(22:00–02:00)은 두 구간으로 본다.
    return open < close ? now >= open && now < close : now >= open || now < close;
  }

  static int _minutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
