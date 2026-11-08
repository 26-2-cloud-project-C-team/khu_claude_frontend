/// 필요 조건(US-02 A). 다중 선택, AND로 적용한다.
enum Requirement {
  free('FREE', '무료 이용'),
  talkable('TALK', '대화 가능'),
  quiet('QUIET', '조용한 분위기'),
  charging('CHARGE', '충전 가능'),
  freeWifi('WIFI', '무료 와이파이');

  const Requirement(this.code, this.label);

  final String code;
  final String label;
}
