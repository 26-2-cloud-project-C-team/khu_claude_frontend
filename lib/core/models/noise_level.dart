enum NoiseLevel {
  quiet('QUIET', '조용함'),
  normal('NORMAL', '보통'),
  loud('LOUD', '시끄러움');

  const NoiseLevel(this.code, this.label);

  final String code;
  final String label;

  /// 모르는 코드는 명세에 따라 [normal]로 바꾼다.
  static NoiseLevel fromCode(String code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return normal;
  }
}
