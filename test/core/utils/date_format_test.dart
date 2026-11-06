import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/utils/date_format.dart';

void main() {
  group('formatDate', () {
    test('API 일시를 YYYY.MM.DD로 쓰고 시각은 버린다', () {
      expect(
        formatDate(DateTime.parse('2026-10-02T14:20:00+09:00')),
        '2026.10.02',
      );
    });

    test('KST 자정 직후는 UTC로 전날이어도 KST 날짜로 쓴다', () {
      final dateTime = DateTime.parse('2026-10-23T00:10:00+09:00');

      expect(dateTime.toUtc().day, 22);
      expect(formatDate(dateTime), '2026.10.23');
    });

    test('다른 offset으로 온 값도 KST 날짜로 바꾼다', () {
      expect(formatDate(DateTime.parse('2026-10-23T15:30:00Z')), '2026.10.24');
      expect(
        formatDate(DateTime.parse('2026-10-23T10:00:00-05:00')),
        '2026.10.24',
      );
    });

    test('기기 시간대로 만든 DateTime도 같은 순간의 KST 날짜로 쓴다', () {
      final instant = DateTime.utc(2026, 12, 31, 15);

      expect(formatDate(instant.toLocal()), '2027.01.01');
      expect(formatDate(instant), '2027.01.01');
    });
  });

  group('formatHours', () {
    test('여는 시각과 닫는 시각을 대시로 잇는다', () {
      expect(formatHours('09:00', '22:00'), '09:00 – 22:00');
    });

    test('24시간 운영', () {
      expect(formatHours('00:00', '24:00'), '00:00 – 24:00');
      expect(formatHours('09:00', '09:00'), '00:00 – 24:00');
    });

    test('자정을 넘기는 시간은 받은 그대로 쓴다', () {
      expect(formatHours('22:00', '02:00'), '22:00 – 02:00');
    });
  });
}
