import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:team_frontend/app.dart';
import 'package:team_frontend/core/location/location_repository.dart';
import 'package:team_frontend/core/network/api_client.dart';
import 'package:team_frontend/features/admin_auth/data/admin_auth_repository.dart';
import 'package:team_frontend/features/admin_auth/models/admin_user.dart';
import 'package:team_frontend/features/admin_auth/viewmodels/admin_auth_view_model.dart';
import 'package:team_frontend/features/directions/data/directions_repository.dart';
import 'package:team_frontend/features/feedback/data/feedback_repository.dart';
import 'package:team_frontend/features/search/data/search_repository.dart';

import 'fakes/fake_directions_repository.dart';
import 'fakes/fake_feedback_repository.dart';
import 'fakes/fake_location_repository.dart';
import 'fakes/fake_search_repository.dart';

void main() {
  testWidgets('첫 화면이 뜬다', (tester) async {
    final apiClient = ApiClient();
    addTearDown(apiClient.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: apiClient),

          Provider<AdminAuthRepository>.value(
            value: _FakeAdminAuthRepository(),
          ),

          ChangeNotifierProvider<AdminAuthViewModel>(
            create: (context) => AdminAuthViewModel(
              repository: context.read<AdminAuthRepository>(),
              apiClient: context.read<ApiClient>(),
            ),
          ),

          // 사용자 화면은 Repository를 Provider로 받는다. 실제 구현체 대신 Fake를 넣는다.
          Provider<SearchRepository>.value(value: FakeSearchRepository()),
          Provider<LocationRepository>.value(value: FakeLocationRepository()),
          Provider<DirectionsRepository>.value(value: FakeDirectionsRepository()),
          Provider<FeedbackRepository>.value(value: FakeFeedbackRepository()),
        ],
        child: const App(),
      ),
    );

    await tester.pump();

    expect(find.byType(Scaffold), findsOneWidget);
  });
}

class _FakeAdminAuthRepository implements AdminAuthRepository {
  @override
  Future<AdminUser> signInWithGoogleIdToken(String idToken) async {
    return const AdminUser(name: '테스트 관리자', email: 'test@example.com');
  }

  @override
  Future<AdminUser?> fetchCurrentAdmin() async {
    return null;
  }

  @override
  Future<void> signOut() async {}
}
