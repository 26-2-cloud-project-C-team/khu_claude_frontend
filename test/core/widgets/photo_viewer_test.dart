import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/models/space_photo.dart';
import 'package:team_frontend/core/widgets/photo_viewer.dart';

import '../../helpers/pump_test_app.dart';

const _photos = [
  SpacePhoto(
    id: 'e',
    url: 'https://cdn.example.com/e.webp',
    tag: PhotoTag.entrance,
  ),
  SpacePhoto(
    id: 'a',
    url: 'https://cdn.example.com/a.webp',
    tag: PhotoTag.approach,
  ),
  SpacePhoto(
    id: 'i',
    url: 'https://cdn.example.com/i.webp',
    tag: PhotoTag.inside,
  ),
  SpacePhoto(id: 'x', url: 'https://cdn.example.com/x.webp'),
];

Future<void> _open(WidgetTester tester, {int initialIndex = 0}) async {
  await tester.pumpTestApp(
    Builder(
      builder: (context) => TextButton(
        onPressed: () => showPhotoViewer(
          context: context,
          photos: _photos,
          initialIndex: initialIndex,
        ),
        child: const Text('열기'),
      ),
    ),
  );
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('누른 사진부터 위치와 태그를 보여준다', (tester) async {
    await _open(tester, initialIndex: 1);

    expect(find.text('2 / 4'), findsOneWidget);
    expect(find.text('가는 길'), findsOneWidget);
  });

  testWidgets('좌우로 밀어 다음·이전 사진으로 넘긴다', (tester) async {
    await _open(tester, initialIndex: 2);

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('4 / 4'), findsOneWidget);
    expect(find.text('내부'), findsNothing, reason: '추가 사진은 태그가 없다');

    await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('3 / 4'), findsOneWidget);
    expect(find.text('내부'), findsOneWidget);
  });

  testWidgets('닫기 버튼으로 닫는다', (tester) async {
    await _open(tester);

    await tester.tap(find.bySemanticsLabel('닫기'));
    await tester.pumpAndSettle();

    expect(find.byType(PhotoViewer), findsNothing);
  });

  testWidgets('아래로 충분히 밀면 닫고, 조금만 밀면 그대로 둔다', (tester) async {
    await _open(tester);

    await tester.timedDrag(
      find.byType(PageView),
      const Offset(0, 60),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewer), findsOneWidget);
    expect(find.text('1 / 4'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewer), findsNothing);
  });
}
