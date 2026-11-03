import '../../../core/models/noise.dart';
import '../../../core/models/photo_tag.dart';
import '../../../core/utils/geo.dart';

class SpacePhoto {
  const SpacePhoto({required this.url, this.tag});

  final String url;
  final PhotoTag? tag;
}

class SpaceReview {
  const SpaceReview({required this.rating, required this.createdAt, this.text});

  final int rating;
  final DateTime createdAt;

  /// 별점만 남긴 의견은 null.
  final String? text;
}

/// 재조사 결과(US-04 이용 의견 영역의 Q&A).
class ReinspectionAnswer {
  const ReinspectionAnswer({required this.question, required this.answer, required this.checkedAt});

  final String question;
  final String answer;
  final DateTime checkedAt;
}

/// 후보 상세(US-04)에 필요한 공간 정보. U2 `candidates[]`, U3 응답.
// TODO: 필드 이름·타입은 API 명세 3장과 대조해 맞춘다(명세 열람 전 화면 설계서 기준).
class CandidateDetail {
  const CandidateDetail({
    required this.spaceId,
    required this.name,
    required this.buildingName,
    required this.buildingLocation,
    required this.floor,
    required this.locationGuide,
    required this.photos,
    required this.distanceMeters,
    required this.availableNow,
    required this.opensAt,
    required this.closesAt,
    required this.ratingAverage,
    required this.ratingCount,
    required this.tableCount,
    required this.maxPerTable,
    required this.chargeableTableCount,
    required this.freeWifi,
    required this.noise,
    required this.isCafe,
    this.note,
    this.pros,
    this.cons,
    this.recentReviews = const [],
    this.answers = const [],
  });

  final int spaceId;

  /// 예: 중앙도서관 4층 열람실
  final String name;
  final String buildingName;

  /// 길찾기 목적지와 30m 도착 판정 기준.
  final GeoPoint buildingLocation;

  /// 예: 4층
  final String floor;

  /// 예: 엘리베이터에서 내려 왼쪽 끝
  final String locationGuide;

  final List<SpacePhoto> photos;

  /// 출발점에서의 직선거리(m).
  final double distanceMeters;
  final bool availableNow;

  /// 오늘 이용 시간 'HH:mm'. 오늘 쉬면 둘 다 null.
  final String? opensAt;
  final String? closesAt;

  /// 평가가 없으면 null.
  final double? ratingAverage;
  final int ratingCount;

  final int tableCount;
  final int maxPerTable;
  final int chargeableTableCount;
  final bool freeWifi;
  final Noise noise;
  final bool isCafe;

  /// 비고(출입·취식 규칙 등). 카페면 화면에서 앞에 '카페'를 붙인다.
  final String? note;
  final String? pros;
  final String? cons;
  final List<SpaceReview> recentReviews;
  final List<ReinspectionAnswer> answers;

  int get walkMinutes => walkingMinutes(distanceMeters);

  /// '충전되는 테이블 80%'
  int get chargeablePercent =>
      tableCount == 0 ? 0 : (chargeableTableCount * 100 / tableCount).round();
}
