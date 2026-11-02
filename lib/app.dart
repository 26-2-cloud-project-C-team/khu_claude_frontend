import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';

// 경로 정의는 lib/app/router.dart가 생기면 그쪽으로 옮긴다.
final _router = GoRouter(
  routes: [GoRoute(path: '/', builder: (_, _) => const Scaffold())],
);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(theme: AppTheme.light, routerConfig: _router);
  }
}
