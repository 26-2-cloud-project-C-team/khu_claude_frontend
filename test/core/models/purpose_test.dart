import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/models/purpose.dart';

void main() {
  test('코드와 enum을 왕복 변환한다', () {
    for (final purpose in Purpose.values) {
      expect(Purpose.fromCode(purpose.code), purpose);
    }
  });

  test('코드와 표시 문구', () {
    expect(
      {for (final p in Purpose.values) p.code: p.label},
      {'TEAM': '팀 프로젝트 · 회의', 'CHAT': '사담', 'SOLO': '개인 작업'},
    );
  });

  test('모르는 코드는 null이라 목록에서 걸러낼 수 있다', () {
    expect(Purpose.fromCode('STUDY'), isNull);
    expect(['TEAM', 'STUDY', 'SOLO'].map(Purpose.fromCode).nonNulls, [
      Purpose.team,
      Purpose.solo,
    ]);
  });
}
