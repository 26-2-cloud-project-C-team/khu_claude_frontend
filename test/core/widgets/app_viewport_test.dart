import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/widgets/app_viewport.dart';

void main() {
  Future<Rect> contentRect(WidgetTester tester, Size screen) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const content = Key('content');
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: AppViewport(child: SizedBox.expand(key: content)),
      ),
    );
    return tester.getRect(find.byKey(content));
  }

  testWidgets('휴대폰 너비에서는 화면을 꽉 채운다', (tester) async {
    final rect = await contentRect(tester, const Size(390, 844));

    expect(rect, const Rect.fromLTWH(0, 0, 390, 844));
  });

  testWidgets('넓은 화면에서는 최대 너비 480 열을 가운데에 둔다', (tester) async {
    final rect = await contentRect(tester, const Size(1280, 800));

    expect(rect.width, AppViewport.maxWidth);
    expect(rect.center.dx, 640);
    expect(rect.height, 800);
  });
}
