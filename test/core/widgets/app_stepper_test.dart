import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/theme/app_colors.dart';
import 'package:team_frontend/core/widgets/app_stepper.dart';

import '../../helpers/pump_test_app.dart';

void main() {
  Color? iconColor(WidgetTester tester, IconData icon) =>
      tester.widget<Icon>(find.byIcon(icon)).color;

  group('큰 스테퍼', () {
    Future<List<int>> pump(WidgetTester tester, int value) async {
      final changes = <int>[];
      await tester.pumpTestApp(
        Center(
          child: AppStepper(
            value: value,
            min: 1,
            max: 10,
            unit: '명',
            onChanged: changes.add,
          ),
        ),
      );
      return changes;
    }

    testWidgets('값에 단위를 붙여 보여준다', (tester) async {
      await pump(tester, 3);

      expect(find.text('3명'), findsOneWidget);
    });

    testWidgets('−/+를 누르면 1씩 바뀐 값을 알린다', (tester) async {
      final changes = await pump(tester, 3);

      await tester.tap(find.byIcon(Icons.remove));
      await tester.tap(find.byIcon(Icons.add));

      expect(changes, [2, 4]);
    });

    testWidgets('최솟값에서는 −가 비활성이다', (tester) async {
      final changes = await pump(tester, 1);

      await tester.tap(find.byIcon(Icons.remove));

      expect(changes, isEmpty);
      expect(iconColor(tester, Icons.remove), AppColors.gray400);
      expect(iconColor(tester, Icons.add), AppColors.gray700);
    });

    testWidgets('최댓값에서는 +가 비활성이다', (tester) async {
      final changes = await pump(tester, 10);

      await tester.tap(find.byIcon(Icons.add));

      expect(changes, isEmpty);
      expect(iconColor(tester, Icons.add), AppColors.gray400);
      expect(iconColor(tester, Icons.remove), AppColors.gray700);
    });

    testWidgets('버튼 크기는 52다', (tester) async {
      await pump(tester, 3);

      final button = find.ancestor(
        of: find.byIcon(Icons.add),
        matching: find.byType(Container),
      );
      expect(tester.getSize(button.first), const Size(52, 52));
    });
  });

  group('행 스테퍼', () {
    Future<List<int>> pump(WidgetTester tester, int value) async {
      final changes = <int>[];
      await tester.pumpTestApp(
        Center(
          child: AppStepperRow(
            label: '테이블',
            value: value,
            min: 0,
            max: 30,
            unit: '개',
            onChanged: changes.add,
          ),
        ),
      );
      return changes;
    }

    testWidgets('이름과 단위 붙은 값을 한 줄에 보여준다', (tester) async {
      await pump(tester, 10);

      expect(find.text('테이블'), findsOneWidget);
      expect(find.text('10개'), findsOneWidget);
      expect(tester.getSize(find.byType(AppStepperRow)).height, 56);
    });

    testWidgets('최솟값에서는 −가 비활성이고 +는 동작한다', (tester) async {
      final changes = await pump(tester, 0);

      await tester.tap(find.byIcon(Icons.remove));
      await tester.tap(find.byIcon(Icons.add));

      expect(changes, [1]);
    });

    testWidgets('버튼은 36으로 보이지만 터치 영역은 44 이상이다', (tester) async {
      await pump(tester, 10);

      final button = find.ancestor(
        of: find.byIcon(Icons.add),
        matching: find.byType(Container),
      );
      expect(tester.getSize(button.first), const Size(36, 36));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    });
  });
}
