import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/app.dart';

void main() {
  testWidgets('첫 화면이 뜬다', (tester) async {
    await tester.pumpWidget(const App());

    expect(find.byType(Scaffold), findsOneWidget);
  });
}
