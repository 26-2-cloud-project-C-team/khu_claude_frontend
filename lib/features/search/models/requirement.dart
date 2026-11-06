/// 필요 조건(US-02 A). 다중 선택, AND로 적용한다.
// TODO: 코드값은 API 명세 2장과 대조해 맞춘다(명세 열람 전 임시값).
enum Requirement {
  free('FREE', '무료 이용'),
  talkable('TALKABLE', '대화 가능'),
  quiet('QUIET', '조용한 분위기'),
  charging('CHARGING', '충전 가능'),
  freeWifi('FREE_WIFI', '무료 와이파이');

  const Requirement(this.code, this.label);

  final String code;
  final String label;
}
