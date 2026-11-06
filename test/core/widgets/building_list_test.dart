import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/models/building.dart';
import 'package:team_frontend/core/theme/app_colors.dart';
import 'package:team_frontend/core/widgets/building_list.dart';

import '../../helpers/pump_test_app.dart';

Building _building(String id, String name) => Building(
  id: id,
  name: name,
  lat: 37.24,
  lng: 127.08,
  floorRange: const FloorRange(min: 1, max: 4),
);

final _library = _building('1', '중앙도서관(대학본부)');
final _engineering = _building('2', '공학관');
final _student = _building('3', '학생회관');
final _buildings = [_student, _library, _engineering];

List<String> _rowNames(WidgetTester tester) => [
  for (final text in tester.widgetList<Text>(
    find.descendant(of: find.byType(ListView), matching: find.byType(Text)),
  ))
    if (_buildings.any((b) => b.name == text.data)) text.data!,
];

void main() {
  group('BuildingList', () {
    Future<List<Building>> pumpList(
      WidgetTester tester, {
      Building? selected,
      String? Function(Building)? captionOf,
    }) async {
      final selections = <Building>[];
      await tester.pumpTestApp(
        BuildingList(
          buildings: _buildings,
          selected: selected,
          captionOf: captionOf,
          header: const Text('출발할 건물을 선택해주세요'),
          onSelected: selections.add,
        ),
      );
      return selections;
    }

    testWidgets('머리말과 가나다순 건물 목록을 보여준다', (tester) async {
      await pumpList(tester);

      expect(find.text('출발할 건물을 선택해주세요'), findsOneWidget);
      expect(_rowNames(tester), ['공학관', '중앙도서관(대학본부)', '학생회관']);
    });

    testWidgets('입력하는 즉시 이름으로 거르고, 지우면 전체 목록이다', (tester) async {
      await pumpList(tester);

      await tester.enterText(find.byType(TextField), '도서');
      await tester.pump();
      expect(_rowNames(tester), ['중앙도서관(대학본부)']);

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(_rowNames(tester), ['공학관', '중앙도서관(대학본부)', '학생회관']);
    });

    testWidgets('띄어쓰기가 달라도 찾는다', (tester) async {
      await pumpList(tester);

      await tester.enterText(find.byType(TextField), '중앙 도서관');
      await tester.pump();

      expect(_rowNames(tester), ['중앙도서관(대학본부)']);
    });

    testWidgets('행을 누르면 확인 없이 그 건물을 넘긴다', (tester) async {
      final selections = await pumpList(tester);

      await tester.tap(find.text('학생회관'));

      expect(selections, [_student]);
    });

    testWidgets('보조 문구와 선택 상태를 보여준다', (tester) async {
      await pumpList(
        tester,
        selected: _engineering,
        captionOf: (b) => b == _library ? '직선 400m' : null,
      );

      expect(find.text('직선 400m'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('공학관')).style!.color,
        AppColors.primary,
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  group('showBuildingSelectSheet', () {
    Future<List<Building?>> pumpSheet(WidgetTester tester) async {
      final results = <Building?>[];
      await tester.pumpTestApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(
              await showBuildingSelectSheet(
                context: context,
                title: '건물을 선택해주세요',
                buildings: _buildings,
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

    testWidgets('행을 누르면 그 건물로 바로 닫힌다', (tester) async {
      final results = await pumpSheet(tester);

      await tester.enterText(find.byType(TextField), '공학');
      await tester.pump();
      await tester.tap(find.text('공학관'));
      await tester.pumpAndSettle();

      expect(results, [_engineering]);
      expect(find.text('건물을 선택해주세요'), findsNothing);
    });

    testWidgets('바깥을 누르면 null로 닫힌다', (tester) async {
      final results = await pumpSheet(tester);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(results, [null]);
    });
  });
}
