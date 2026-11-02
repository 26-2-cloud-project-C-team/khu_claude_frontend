const int minRating = 1;
const int maxRating = 5;

/// 후기 최대 글자 수(US-07 B).
const int reviewMaxLength = 200;

/// 재조사 상세 내용 최대 글자 수(US-07 C).
const int reinspectionDetailMaxLength = 300;

/// 별점 문구.
String ratingLabel(int rating) => switch (rating) {
      1 => '아쉬워요',
      2 => '그저 그래요',
      3 => '괜찮아요',
      4 => '만족해요',
      5 => '최고예요',
      _ => throw RangeError.range(rating, minRating, maxRating, 'rating'),
    };
