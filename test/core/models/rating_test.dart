import 'package:flutter_test/flutter_test.dart';
import 'package:team_frontend/core/models/rating.dart';

void main() {
  test('별점별 문구', () {
    expect(
      [for (var r = minRating; r <= maxRating; r++) ratingLabel(r)],
      ['아쉬워요', '그저 그래요', '괜찮아요', '만족해요', '최고예요'],
    );
  });

  test('범위 밖 별점은 RangeError', () {
    expect(() => ratingLabel(0), throwsRangeError);
    expect(() => ratingLabel(6), throwsRangeError);
  });
}
