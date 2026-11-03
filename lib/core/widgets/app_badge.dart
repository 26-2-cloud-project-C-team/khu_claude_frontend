import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 공개는 [positive], 비공개는 [neutral], 재조사 요청 N은 [primary]를 쓴다.
enum AppBadgeTone { positive, neutral, primary, plain }

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.tone = AppBadgeTone.neutral,
    this.leading,
    this.trailing,
  });

  final String label;
  final AppBadgeTone tone;
  final Widget? leading;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      AppBadgeTone.positive => (AppColors.positiveTint, AppColors.positive),
      AppBadgeTone.neutral => (AppColors.gray100, AppColors.gray600),
      AppBadgeTone.primary => (AppColors.primaryTint, AppColors.primary),
      AppBadgeTone.plain => (AppColors.gray50, AppColors.gray900),
    };
    final leading = this.leading;
    final trailing = this.trailing;

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 3,
        children: [
          ?leading,
          Text(label, style: AppTypography.label.copyWith(color: foreground)),
          if (trailing != null)
            Text(
              trailing,
              style: AppTypography.label.copyWith(color: AppColors.gray500),
            ),
        ],
      ),
    );
  }
}
