import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/theme/app_colors.dart';
import 'package:team_frontend/core/widgets/app_bottom_sheet.dart';

import '../../helpers/pump_test_app.dart';

void main() {
  const floors = ['1층', '2층', '3층', '4층'];

  Future<List<String?>> pumpSelectSheet(
    WidgetTester tester, {
    bool expanded = false,
  }) async {
    final results = <String?>[];
    await tester.pumpTestApp(
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => results.add(
            await showAppSelectSheet<String>(
              context: context,
              title: '층을 선택해주세요',
              subtitle: '중앙도서관(대학본부)',
              options: floors,
              labelOf: (floor) => floor,
              selected: '4층',
              expanded: expanded,
            ),
          ),
          child: const Text('열기'),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('하나를 고르는 시트는 항목을 누르면 그 값으로 바로 닫힌다', (tester) async {
    final results = await pumpSelectSheet(tester);

    await tester.tap(find.text('2층'));
    await tester.pumpAndSettle();

    expect(results, ['2층']);
    expect(find.text('층을 선택해주세요'), findsNothing);
  });

  testWidgets('바깥을 누르면 값 없이 닫혀 이전 값을 그대로 둔다', (tester) async {
    final results = await pumpSelectSheet(tester);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(results, [null]);
    expect(find.text('층을 선택해주세요'), findsNothing);
  });

  testWidgets('아래로 내리면 값 없이 닫힌다', (tester) async {
    final results = await pumpSelectSheet(tester);

    await tester.drag(find.text('층을 선택해주세요'), const Offset(0, 500));
    await tester.pumpAndSettle();

    expect(results, [null]);
  });

  testWidgets('제목·보조 문구와 선택된 항목의 체크를 보여준다', (tester) async {
    await pumpSelectSheet(tester);

    expect(find.text('중앙도서관(대학본부)'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
    final selectedColor = tester
        .renderObject<RenderParagraph>(find.text('4층'))
        .text
        .style!
        .color;
    expect(selectedColor, AppColors.primary);

    final row = tester.getRect(
      find.ancestor(of: find.text('4층'), matching: find.byType(AppSheetOption)),
    );
    expect(tester.getRect(find.byIcon(Icons.check)).right, row.right);
  });

  testWidgets('큰 시트는 화면 위에서 120을 남기고 올라온다', (tester) async {
    await pumpSelectSheet(tester, expanded: true);

    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final sheet = tester.getRect(find.byType(BottomSheet));
    expect(sheet.top, closeTo(120, 0.5));
    expect(sheet.bottom, closeTo(screenHeight, 0.5));
  });

  testWidgets('여러 값을 맞추는 시트는 확인을 눌러야 값과 함께 닫힌다', (tester) async {
    final results = <String?>[];
    await tester.pumpTestApp(
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => results.add(
            await showAppBottomSheet<String>(
              context: context,
              title: '이용 가능 시간을 선택해주세요',
              builder: (context) {
                var start = '09:00';
                return StatefulBuilder(
                  builder: (context, setState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => start = '10:00'),
                        child: Text('시작 $start'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(start),
                        child: const Text('확인'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          child: const Text('열기'),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('시작 09:00'));
    await tester.pumpAndSettle();
    expect(find.text('이용 가능 시간을 선택해주세요'), findsOneWidget);
    expect(results, isEmpty);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(results, ['10:00']);
  });

  testWidgets('제목 없이 열 수 있다', (tester) async {
    await tester.pumpTestApp(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showAppBottomSheet<void>(
            context: context,
            builder: (_) => const Text('로그아웃'),
          ),
          child: const Text('열기'),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    expect(find.text('로그아웃'), findsOneWidget);
  });
}
