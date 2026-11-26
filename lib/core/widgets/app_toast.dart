import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// DS-00 토스트. 한 줄 · 높이 44 · 반경 12 · Gray 900 바탕이며, 액션은 하나까지 둔다.
///
/// 표시 시간(3초)과 화면을 벗어날 때 지우는 일은 띄운 화면이 맡는다. SnackBar는 접근성
/// 탐색이 켜져 있으면 액션이 있는 알림을 자동으로 닫지 않아 직접 그린다.
class AppToast extends StatelessWidget {
  const AppToast({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  static const duration = Duration(seconds: 3);

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        height: 44,
        padding: const EdgeInsets.only(left: 16, right: 4),
        decoration: BoxDecoration(
          color: AppColors.gray900,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body2.copyWith(color: AppColors.white),
              ),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  foregroundColor: AppColors.white,
                ),
                child: Text(
                  actionLabel!,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
