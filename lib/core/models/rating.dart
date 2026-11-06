const int minRating = 1;
const int maxRating = 5;

String ratingLabel(int rating) => switch (rating) {
  1 => '아쉬워요',
  2 => '그저 그래요',
  3 => '괜찮아요',
  4 => '만족해요',
  5 => '최고예요',
  _ => throw RangeError.range(rating, minRating, maxRating, 'rating'),
};
