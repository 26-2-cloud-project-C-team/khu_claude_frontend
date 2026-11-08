import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/models/reinspection_category.dart';
import 'package:team_frontend/core/network/api_client.dart';
import 'package:team_frontend/features/feedback/data/feedback_repository_impl.dart';

import '../../../fakes/fake_http_adapter.dart';

void main() {
  FeedbackRepositoryImpl repoWith(FakeHttpAdapter adapter) =>
      FeedbackRepositoryImpl(ApiClient(adapter: adapter));

  test('U4 오늘 남긴 별점 · 후기를 읽는다', () async {
    final adapter = FakeHttpAdapter(
      (_) => jsonResponse(200, {
        'review': {'rating': 4, 'comment': '좋아요', 'createdAt': '2026-11-01T13:05:00+09:00'},
      }),
    );

    final review = await repoWith(adapter).fetchTodayReview('s1');

    expect(adapter.lastRequest.method, 'GET');
    expect(adapter.lastRequest.uri.path, '/api/spaces/s1/my-review');
    expect(review!.rating, 4);
    expect(review.text, '좋아요');
  });

  test('U4 review가 null이면 null이다', () async {
    final adapter = FakeHttpAdapter((_) => jsonResponse(200, {'review': null}));

    expect(await repoWith(adapter).fetchTodayReview('s1'), isNull);
  });

  test('U5 별점만 등록해도 comment를 null로 보낸다', () async {
    final adapter = FakeHttpAdapter(
      (_) => jsonResponse(201, {
        'review': {'rating': 5, 'comment': null, 'createdAt': '2026-11-01T13:05:00+09:00'},
      }),
    );

    await repoWith(adapter).submitReview(spaceId: 's1', rating: 5);

    expect(adapter.lastRequest.method, 'PUT');
    expect(adapter.lastRequest.uri.path, '/api/spaces/s1/my-review');
    expect(adapter.bodies.last, {'rating': 5, 'comment': null});
  });

  test('U6 항목 코드를 화면 순서대로 보낸다', () async {
    final adapter = FakeHttpAdapter(
      (_) => jsonResponse(201, {
        'reinspection': {
          'id': 'r1',
          'categories': ['TIME_MOOD', 'LOCATION_PHOTO'],
          'detail': null,
          'createdAt': '2026-11-01T14:40:00+09:00',
        },
      }),
    );

    await repoWith(adapter).requestReinspection(
      spaceId: 's1',
      categories: {ReinspectionCategory.locationPhoto, ReinspectionCategory.timeMood},
    );

    expect(adapter.lastRequest.method, 'PUT');
    expect(adapter.lastRequest.uri.path, '/api/spaces/s1/my-reinspection');
    expect(adapter.bodies.last, {
      'categories': ['TIME_MOOD', 'LOCATION_PHOTO'],
      'detail': null,
    });
  });
}
