import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/theme/app_colors.dart';
import 'package:team_frontend/core/theme/app_theme.dart';
import 'package:team_frontend/core/widgets/app_button.dart';
import 'package:team_frontend/core/widgets/app_screen_parts.dart';
import 'package:team_frontend/core/widgets/app_step_scaffold.dart';

void main() {
  void useScreen(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget stepScreen({
    int step = 0,
    int filledSteps = 1,
    String title = '현재 위치에서 출발할까요?',
    String? subtitle = '현재 위치를 기준으로 가까운 공간을 찾아 드려요',
    VoidCallback? onCta,
    VoidCallback? onBack,
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: AppStepScaffold(
        step: step,
        filledSteps: filledSteps,
        totalSteps: 5,
        title: title,
        subtitle: subtitle,
        body: const SizedBox(height: 80, child: Text('내용')),
        ctaLabel: '다음',
        onCta: onCta,
        onBack: onBack ?? () {},
      ),
    );
  }

  List<Color?> segmentColors(WidgetTester tester) => tester
      .widgetList<Container>(
        find.descendant(
          of: find.byType(AppProgressBar),
          matching: find.byType(Container),
        ),
      )
      .map((c) => (c.decoration! as BoxDecoration).color)
      .toList();

  testWidgets('진행 바는 채울 칸 수만큼 Primary, 나머지는 Gray 100이다', (tester) async {
    await tester.pumpWidget(stepScreen(filledSteps: 2));

    expect(segmentColors(tester), [
      AppColors.primary,
      AppColors.primary,
      AppColors.gray100,
      AppColors.gray100,
      AppColors.gray100,
    ]);
  });

  testWidgets('진행 바 칸은 같은 너비로 나뉜다', (tester) async {
    await tester.pumpWidget(stepScreen());

    final widths = tester
        .widgetList(
          find.descendant(
            of: find.byType(AppProgressBar),
            matching: find.byType(Container),
          ),
        )
        .map((c) => tester.getSize(find.byWidget(c)).width)
        .toSet();
    expect(widths, hasLength(1));
  });

  testWidgets('onCta가 없으면 CTA가 오류 문구 없이 비활성이다', (tester) async {
    await tester.pumpWidget(stepScreen());

    final button = tester.widget<AppButton>(find.byType(AppButton));
    expect(button.onPressed, isNull);
    expect(find.byType(TextButton), findsOneWidget);
    expect(tester.widget<TextButton>(find.byType(TextButton)).enabled, isFalse);
  });

  testWidgets('onCta가 있으면 CTA를 누를 수 있다', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(stepScreen(onCta: () => pressed++));

    await tester.tap(find.text('다음'));

    expect(pressed, 1);
  });

  testWidgets('뒤로가기를 누르면 onBack이 호출된다', (tester) async {
    var back = 0;
    await tester.pumpWidget(stepScreen(onBack: () => back++));

    await tester.tap(find.bySemanticsLabel('뒤로'));

    expect(back, 1);
  });

  testWidgets('390×844에서 US-01 A 시안과 여백이 맞는다', (tester) async {
    useScreen(tester, const Size(390, 844));
    await tester.pumpWidget(stepScreen());

    final segments = find.descendant(
      of: find.byType(AppProgressBar),
      matching: find.byType(Container),
    );
    expect(tester.getRect(segments.first).top, 56);
    expect(tester.getRect(segments.first).left, 20);
    expect(tester.getRect(segments.last).right, 390 - 20);

    final title = tester.getRect(find.text('현재 위치에서 출발할까요?'));
    expect(title.left, 20);
    expect(title.top, closeTo(56 + 3 + 24, 0.5));

    final subtitle = tester.getRect(find.text('현재 위치를 기준으로 가까운 공간을 찾아 드려요'));
    expect(subtitle.top - title.bottom, closeTo(8, 0.5));
    expect(
      tester.getRect(find.text('내용')).top - subtitle.bottom,
      closeTo(32, 0.5),
    );

    final cta = tester.getRect(find.byType(AppButton));
    expect(cta.left, 20);
    expect(cta.right, 390 - 20);
    expect(cta.bottom, 844 - 34);
  });

  testWidgets('부제가 없으면 내용이 제목 아래 24부터 시작한다', (tester) async {
    await tester.pumpWidget(stepScreen(subtitle: null));

    final title = tester.getRect(find.text('현재 위치에서 출발할까요?'));
    expect(
      tester.getRect(find.text('내용')).top - title.bottom,
      closeTo(24, 0.5),
    );
  });

  group('단계 전환', () {
    Future<void> moveTo(WidgetTester tester, int step, String title) async {
      await tester.pumpWidget(stepScreen(step: step, title: title));
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('다음 단계는 오른쪽에서 들어오고 이전 내용은 왼쪽으로 나간다', (tester) async {
      await tester.pumpWidget(stepScreen(step: 0, title: '1단계'));
      await moveTo(tester, 1, '2단계');

      expect(tester.getRect(find.text('2단계')).left, greaterThan(20));
      expect(tester.getRect(find.text('1단계')).left, lessThan(20));

      await tester.pumpAndSettle();
      expect(find.text('1단계'), findsNothing);
      expect(tester.getRect(find.text('2단계')).left, 20);
    });

    testWidgets('이전 단계는 왼쪽에서 들어오고 지금 내용은 오른쪽으로 나간다', (tester) async {
      await tester.pumpWidget(stepScreen(step: 1, title: '2단계'));
      await moveTo(tester, 0, '1단계');

      expect(tester.getRect(find.text('1단계')).left, lessThan(20));
      expect(tester.getRect(find.text('2단계')).left, greaterThan(20));
    });
  });
}
