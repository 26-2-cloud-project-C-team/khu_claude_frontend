// TODO(A-07): 공용 코드값 작업(docs/tasks/platform/07)이 들어오면 그쪽 정의로 바꾸고 이 파일을 지운다.

/// 이용 목적. API 명세 2장 코드값.
enum Purpose {
  team('TEAM', '팀 프로젝트 · 회의'),
  chat('CHAT', '사담'),
  solo('SOLO', '개인 작업');

  const Purpose(this.code, this.label);

  final String code;
  final String label;

  static Purpose fromCode(String code) => values.firstWhere(
        (v) => v.code == code,
        orElse: () => throw ArgumentError.value(code, 'code', '알 수 없는 이용 목적'),
      );
}
