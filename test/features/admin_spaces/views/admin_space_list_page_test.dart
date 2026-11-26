import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/theme/app_colors.dart';
import 'package:team_frontend/features/admin_spaces/views/admin_space_list_page.dart';

void main() {
  const base = TextStyle(color: AppColors.gray900);

  group('highlightMatches', () {
    test('검색어가 없으면 한 조각 그대로 둔다', () {
      final spans = highlightMatches('중앙도서관', '', base);
      expect(spans.map((s) => s.text), ['중앙도서관']);
      expect(spans.single.style!.color, AppColors.gray900);
    });

    test('일치 부분만 Primary 색으로 나눈다', () {
      final spans = highlightMatches('중앙도서관(대학본부)', '도서관', base);
      expect(spans.map((s) => s.text), ['중앙', '도서관', '(대학본부)']);
      expect(spans[1].style!.color, AppColors.primary);
      expect(spans[0].style!.color, AppColors.gray900);
    });

    test('대소문자를 가리지 않고 여러 번 일치하면 모두 강조한다', () {
      final spans = highlightMatches('S1 s1', 's1', base);
      expect(
        spans.where((s) => s.style!.color == AppColors.primary).map((s) => s.text),
        ['S1', 's1'],
      );
    });
  });
}
