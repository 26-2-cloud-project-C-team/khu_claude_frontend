import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/models/reinspection_category.dart';

void main() {
  test('코드와 enum을 왕복 변환한다', () {
    for (final category in ReinspectionCategory.values) {
      expect(ReinspectionCategory.fromCode(category.code), category);
    }
  });

  test('코드와 표시 문구', () {
    expect(
      {for (final c in ReinspectionCategory.values) c.code: c.label},
      {
        'TIME_MOOD': '이용 시간 · 분위기',
        'TABLE_FACILITY': '테이블 · 시설',
        'LOCATION_PHOTO': '위치 · 사진',
        'ENTRY_FOOD': '출입 · 취식 규칙',
        'CLOSED_MOVED': '폐쇄 · 이전',
        'ETC': '기타',
      },
    );
  });

  test('모르는 코드는 기타로 바꾼다', () {
    expect(ReinspectionCategory.fromCode('PRICE'), ReinspectionCategory.etc);
  });
}
