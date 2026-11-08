enum Purpose {
  team('TEAM', '팀 프로젝트 · 회의'),
  chat('CHAT', '사담'),
  solo('SOLO', '개인 작업');

  const Purpose(this.code, this.label);

  final String code;
  final String label;

  /// 모르는 코드는 `null`이다. 명세상 모르는 목적은 화면에 표시하지 않는다.
  static Purpose? fromCode(String code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}
