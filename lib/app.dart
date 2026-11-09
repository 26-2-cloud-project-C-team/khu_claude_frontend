import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app/router.dart';
import 'features/admin_auth/viewmodels/admin_auth_view_model.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_viewport.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router ??= createRouter(adminAuth: context.read<AdminAuthViewModel>());
  }

  @override
  void dispose() {
    _router?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = _router;
    if (router == null) return const SizedBox.shrink();

    return MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: router,
      builder: (_, child) => AppViewport(child: child!),
    );
  }
}
