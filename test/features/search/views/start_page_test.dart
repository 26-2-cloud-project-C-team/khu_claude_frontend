import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:team_frontend/core/models/purpose.dart';
import 'package:team_frontend/features/search/viewmodels/search_flow_view_model.dart';
import 'package:team_frontend/features/search/views/start_page.dart';

import '../../../helpers/pump_test_app.dart';
import '../../../fakes/fake_location_repository.dart';
import '../../../fakes/fake_search_repository.dart';

void main() {
  testWidgets('목적 타일을 누르면 그 목적으로 시작한다', (tester) async {
    final vm = SearchFlowViewModel(
      searchRepository: FakeSearchRepository(),
      locationRepository: FakeLocationRepository(),
    );
    var started = 0;
    await tester.pumpTestApp(StartPage(viewModel: vm, onStarted: () => started++));

    expect(find.text('어떤 공간을 찾아 드릴까요?'), findsOneWidget);
    await tester.tap(find.text('사담'));

    expect(started, 1);
    expect(vm.condition.purpose, Purpose.chat);
  });

  testWidgets('시작 화면 맨 위에 히어로 애니메이션을 둔다', (tester) async {
    final vm = SearchFlowViewModel(
      searchRepository: FakeSearchRepository(),
      locationRepository: FakeLocationRepository(),
    );
    await tester.pumpTestApp(StartPage(viewModel: vm, onStarted: () {}));

    expect(find.byType(StartHero), findsOneWidget);
    expect(tester.getSize(find.byType(StartHero)).height, 180);
  });

  test('히어로 Lottie는 3초짜리 700×360 컴포지션이다', () async {
    final bytes = await File(StartHero.asset).readAsBytes();
    final composition = await LottieComposition.fromBytes(bytes);

    expect(composition.duration, const Duration(seconds: 3));
    expect(composition.bounds.width, 700);
    expect(composition.bounds.height, 360);
    expect(composition.layers.map((l) => l.name), containsAll(['current-location', 'pin', 'route', 'bubble']));
  });
}
