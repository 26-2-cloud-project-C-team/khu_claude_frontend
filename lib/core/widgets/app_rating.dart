import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_badge.dart';

String _formatAverage(double average) => average.toStringAsFixed(1);

/// `★4.6 (32)` 형태의 배지(후보 상세 상단).
class AppRatingBadge extends StatelessWidget {
  const AppRatingBadge({super.key, required this.average, required this.count});

  final double average;
  final int count;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      tone: AppBadgeTone.plain,
      leading: const Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
      label: _formatAverage(average),
      trailing: '($count)',
    );
  }
}

/// `★ 4.6 (32)` 형태의 한 줄 요약(이용 의견 제목 옆).
class AppRatingSummary extends StatelessWidget {
  const AppRatingSummary({
    super.key,
    required this.average,
    required this.count,
  });

  final double average;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(
            text: '★ ',
            style: TextStyle(color: AppColors.gold),
          ),
          TextSpan(
            text: _formatAverage(average),
            style: const TextStyle(color: AppColors.gray900),
          ),
          TextSpan(text: ' ($count)'),
        ],
      ),
      style: AppTypography.body2,
    );
  }
}

/// 점수만큼 Gold로 채운 별 다섯 개(의견 목록의 별점 표시).
class AppStars extends StatelessWidget {
  const AppStars({super.key, required this.rating, this.size = 14});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$rating점',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= 5; i++)
              Icon(
                Icons.star_rounded,
                size: size,
                color: i <= rating ? AppColors.gold : AppColors.gray200,
              ),
          ],
        ),
      ),
    );
  }
}

/// 1~5를 탭해 고르는 별점 입력. [value]가 null이면 아무것도 고르지 않은 상태다.
class AppRatingInput extends StatelessWidget {
  const AppRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final value = this.value ?? 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        for (var score = 1; score <= 5; score++)
          Semantics(
            label: '$score점',
            selected: score == value,
            button: true,
            child: InkWell(
              onTap: () => onChanged(score),
              splashFactory: NoSplash.splashFactory,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              child: SizedBox.square(
                dimension: 48,
                child: Icon(
                  Icons.star_rounded,
                  size: 40,
                  color: score <= value ? AppColors.gold : AppColors.gray200,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
