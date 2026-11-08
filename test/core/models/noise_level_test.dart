import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/models/noise_level.dart';

void main() {
  test('코드와 enum을 왕복 변환한다', () {
    for (final level in NoiseLevel.values) {
      expect(NoiseLevel.fromCode(level.code), level);
    }
  });

  test('코드와 표시 문구', () {
    expect(
      {for (final n in NoiseLevel.values) n.code: n.label},
      {'QUIET': '조용함', 'NORMAL': '보통', 'LOUD': '시끄러움'},
    );
  });

  test('모르는 코드는 보통으로 바꾼다', () {
    expect(NoiseLevel.fromCode('VERY_LOUD'), NoiseLevel.normal);
  });
}
