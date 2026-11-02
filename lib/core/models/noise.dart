// TODO(A-07): 공용 코드값 작업(docs/tasks/platform/07)이 들어오면 그쪽 정의로 바꾸고 이 파일을 지운다.

/// 조사 당시 소음. API 명세 2장 코드값.
enum Noise {
  quiet('QUIET', '조용함'),
  normal('NORMAL', '보통'),
  loud('LOUD', '시끄러움');

  const Noise(this.code, this.label);

  final String code;
  final String label;

  static Noise fromCode(String code) => values.firstWhere(
        (v) => v.code == code,
        orElse: () => throw ArgumentError.value(code, 'code', '알 수 없는 소음 코드'),
      );
}
