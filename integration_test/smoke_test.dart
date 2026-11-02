import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:team_frontend/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('앱이 오류 없이 첫 화면을 띄운다', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
