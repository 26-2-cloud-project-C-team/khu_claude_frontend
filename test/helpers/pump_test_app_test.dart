import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:team_frontend/core/theme/app_typography.dart';

import '../fakes/fake_example_repository.dart';
import 'pump_test_app.dart';

class _TitleViewModel extends ChangeNotifier {
  _TitleViewModel(this._repository);

  final ExampleRepository _repository;
  String? title;

  Future<void> load() async {
    title = await _repository.fetchTitle();
    notifyListeners();
  }
}

class _TitlePage extends StatelessWidget {
  const _TitlePage();

  @override
  Widget build(BuildContext context) {
    final title = context.watch<_TitleViewModel>().title;
    return Column(
      children: [
        Text(title ?? '불러오는 중'),
        TextButton(
          onPressed: () => context.go('/detail'),
          child: const Text('자세히'),
        ),
      ],
    );
  }
}

void main() {
  testWidgets('Provider로 넣은 ViewModel이 Fake의 값을 그린다', (tester) async {
    final repository = FakeExampleRepository(title: '공학관 라운지');
    final viewModel = _TitleViewModel(repository);

    await tester.pumpTestApp(
      const _TitlePage(),
      providers: [ChangeNotifierProvider.value(value: viewModel)],
    );
    await viewModel.load();
    await tester.pump();

    expect(find.text('공학관 라운지'), findsOneWidget);
    expect(repository.fetchCount, 1);
  });

  testWidgets('앱 테마가 적용되어 기본 글자가 Body1이다', (tester) async {
    await tester.pumpTestApp(const Text('본문'));

    final style = DefaultTextStyle.of(tester.element(find.text('본문'))).style;
    expect(style.fontFamily, AppTypography.fontFamily);
    expect(style.fontSize, AppTypography.body1.fontSize);
  });

  testWidgets('화면 이동은 추가한 경로로 가고 Router로 확인한다', (tester) async {
    final router = await tester.pumpTestApp(
      const _TitlePage(),
      providers: [
        ChangeNotifierProvider(
          create: (_) => _TitleViewModel(FakeExampleRepository()),
        ),
      ],
      routes: [GoRoute(path: '/detail', builder: (_, _) => const Text('상세'))],
    );

    await tester.tap(find.text('자세히'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/detail');
    expect(find.text('상세'), findsOneWidget);
  });
}
