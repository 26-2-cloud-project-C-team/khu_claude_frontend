/// 재조사 요청 항목. 사용자(US-07)와 관리자(AD-04)가 같은 문구로 보여준다.
enum ReinspectionCategory {
  timeMood('TIME_MOOD', '이용 시간 · 분위기'),
  tableFacility('TABLE_FACILITY', '테이블 · 시설'),
  locationPhoto('LOCATION_PHOTO', '위치 · 사진'),
  entryFood('ENTRY_FOOD', '출입 · 취식 규칙'),
  closedMoved('CLOSED_MOVED', '폐쇄 · 이전'),
  etc('ETC', '기타');

  const ReinspectionCategory(this.code, this.label);

  final String code;
  final String label;

  /// 모르는 코드는 명세에 따라 [etc]로 바꾼다.
  static ReinspectionCategory fromCode(String code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return etc;
  }
}
