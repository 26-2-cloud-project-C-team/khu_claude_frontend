import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'app/dependencies.dart';

void main() {
  // 공유 링크(`/spaces/{id}`)와 관리자 주소(`/admin`)를 '#' 없이 받는다. 웹 서버가 없는 경로에 index.html을 돌려준다.
  usePathUrlStrategy();
  runApp(MultiProvider(providers: createDependencies(), child: const App()));
}
