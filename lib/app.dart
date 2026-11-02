import 'package:flutter/material.dart';

import 'app/router.dart';
import 'core/theme/app_theme.dart';

final _router = createRouter();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(theme: AppTheme.light, routerConfig: _router);
  }
}
