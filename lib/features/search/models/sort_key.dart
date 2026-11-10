/// 정렬 기준(US-02 B). 다중 선택, 점수 계산과 정렬은 서버가 한다.
enum SortKey {
  distance('NEAR', '가까운 곳', '출발점에서 직선거리가 짧은 순'),
  largeTable('BIG_TABLE', '큰 테이블', '함께 앉을 수 있는 인원이 많은 순'),
  charging('CHARGE', '충전 편한 곳', '충전되는 테이블 비율이 높은 순');

  const SortKey(this.code, this.label, this.description);

  final String code;
  final String label;
  final String description;
}
