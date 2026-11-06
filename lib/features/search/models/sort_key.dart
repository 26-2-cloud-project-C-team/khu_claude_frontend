/// 정렬 기준(US-02 B). 다중 선택, 점수 계산과 정렬은 서버가 한다.
// TODO: 코드값은 API 명세 2장과 대조해 맞춘다(명세 열람 전 임시값).
enum SortKey {
  distance('DISTANCE', '가까운 곳', '출발점에서 직선거리가 짧은 순'),
  largeTable('LARGE_TABLE', '큰 테이블', '함께 앉을 수 있는 인원이 많은 순'),
  charging('CHARGING', '충전 편한 곳', '충전되는 테이블 비율이 높은 순');

  const SortKey(this.code, this.label, this.description);

  final String code;
  final String label;
  final String description;
}
