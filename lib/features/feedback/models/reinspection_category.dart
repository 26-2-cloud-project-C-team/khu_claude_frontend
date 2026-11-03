/// 재조사 요청 항목(US-07 C). 관리자 AD-04에도 같은 항목명으로 보인다.
/// 순서와 문구는 화면 설계서 US-07 C의 6개 칩을 따른다.
// TODO: 관리자(C)도 쓰므로 core로 옮길지 장재준 님과 정한다. 코드값은 API 명세 2장과 대조한다.
// 확인 필요: ENTRY 문구는 API 명세 '출입 규칙', 설계서 US-07 C '출입 · 취식 규칙'.
enum ReinspectionCategory {
  hours('HOURS', '이용 시간 · 분위기'),
  facility('FACILITY', '테이블 · 시설'),
  location('LOCATION', '위치 · 사진'),
  entry('ENTRY', '출입 · 취식 규칙'),
  closed('CLOSED', '폐쇄 · 이전'),
  etc('ETC', '기타');

  const ReinspectionCategory(this.code, this.label);

  final String code;
  final String label;
}
