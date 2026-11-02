import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:team_frontend/core/theme/app_theme.dart';

extension PumpTestApp on WidgetTester {
  /// [widget]을 앱 테마와 테스트 Router의 `/` 화면에 띄운다.
  ///
  /// [providers]로 Fake를 넣어 만든 ViewModel을 주입한다. 화면 이동을 확인하려면
  /// 이동할 경로를 [routes]로 추가하고, 돌려받은 Router의 `state.uri`를 본다.
  Future<GoRouter> pumpTestApp(
    Widget widget, {
    List<SingleChildWidget> providers = const [],
    List<RouteBase> routes = const [],
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(body: widget),
        ),
        ...routes,
      ],
    );
    addTearDown(router.dispose);

    final app = MaterialApp.router(theme: AppTheme.light, routerConfig: router);
    await pumpWidget(
      providers.isEmpty ? app : MultiProvider(providers: providers, child: app),
    );
    return router;
  }
}
