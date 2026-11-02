import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_selection_mode.dart';

class AppOptionRow extends StatelessWidget {
  const AppOptionRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
    this.mode = AppSelectionMode.single,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final AppSelectionMode mode;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;

    return Semantics(
      checked: selected,
      inMutuallyExclusiveGroup: mode == AppSelectionMode.single,
      child: Material(
        color: selected ? AppColors.primaryTint : AppColors.gray50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.option),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.gray100,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: subtitle == null ? 60 : 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.body1.copyWith(
                            color: selected
                                ? AppColors.primary
                                : AppColors.gray900,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: AppTypography.caption.copyWith(
                              color: selected
                                  ? AppColors.primary.withValues(alpha: 0.8)
                                  : AppColors.gray500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.between),
                  _SelectionIndicator(mode: mode, selected: selected),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.mode, required this.selected});

  final AppSelectionMode mode;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : null,
        borderRadius: BorderRadius.circular(
          mode == AppSelectionMode.single ? 11 : 6,
        ),
        border: selected
            ? null
            : Border.all(color: AppColors.gray300, width: 1.5),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: AppColors.white)
          : null,
    );
  }
}
