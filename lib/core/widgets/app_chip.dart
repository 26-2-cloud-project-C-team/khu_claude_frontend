import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_selection_mode.dart';

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.mode = AppSelectionMode.single,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppSelectionMode mode;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.white : AppColors.gray700;

    return Semantics(
      checked: selected,
      inMutuallyExclusiveGroup: mode == AppSelectionMode.single,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        // 칩은 36으로 보이지만 터치 영역 44를 확보하려고 위아래로 4씩 탭 영역을 늘린다.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Center(
            widthFactor: 1,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.gray100,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTypography.label.copyWith(color: foreground),
                  ),
                  if (selected && mode == AppSelectionMode.multiple) ...[
                    const SizedBox(width: AppSpacing.textLine),
                    Icon(Icons.check, size: 14, color: foreground),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
