import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:team_frontend/app.dart';
import 'package:team_frontend/core/location/location_repository.dart';
import 'package:team_frontend/features/directions/data/directions_repository.dart';
import 'package:team_frontend/features/feedback/data/feedback_repository.dart';
import 'package:team_frontend/features/search/data/search_repository.dart';

import 'fakes/fake_directions_repository.dart';
import 'fakes/fake_feedback_repository.dart';
import 'fakes/fake_location_repository.dart';
import 'fakes/fake_search_repository.dart';

void main() {
  testWidgets('첫 화면이 뜬다', (tester) async {
    // 사용자 화면은 Repository를 Provider로 받는다. 실제 구현체 대신 Fake를 넣는다.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SearchRepository>.value(value: FakeSearchRepository()),
          Provider<LocationRepository>.value(value: FakeLocationRepository()),
          Provider<DirectionsRepository>.value(value: FakeDirectionsRepository()),
          Provider<FeedbackRepository>.value(value: FakeFeedbackRepository()),
        ],
        child: const App(),
      ),
    );

    expect(find.byType(Scaffold), findsOneWidget);
  });
}
