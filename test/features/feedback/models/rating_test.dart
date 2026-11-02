import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/features/feedback/models/rating.dart';

void main() {
  test('별점 문구', () {
    expect([for (var i = 1; i <= 5; i++) ratingLabel(i)],
        ['아쉬워요', '그저 그래요', '괜찮아요', '만족해요', '최고예요']);
  });

  test('범위 밖이면 RangeError', () {
    expect(() => ratingLabel(0), throwsRangeError);
    expect(() => ratingLabel(6), throwsRangeError);
  });
}
