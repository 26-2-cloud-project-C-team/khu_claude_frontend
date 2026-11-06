import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'app/dependencies.dart';

void main() {
  runApp(MultiProvider(providers: createDependencies(), child: const App()));
}
