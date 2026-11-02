import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: switch (variant) {
        AppButtonVariant.primary => _filled(
          background: AppColors.primary,
          pressed: AppColors.primaryPressed,
          foreground: AppColors.white,
        ),
        AppButtonVariant.secondary => _filled(
          background: AppColors.gray100,
          pressed: AppColors.gray200,
          foreground: AppColors.gray900,
        ),
        AppButtonVariant.text => _text,
      },
      child: Text(label),
    );
  }

  static ButtonStyle _filled({
    required Color background,
    required Color pressed,
    required Color foreground,
  }) {
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(56)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      ),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.control)),
        ),
      ),
      textStyle: const WidgetStatePropertyAll(AppTypography.h3),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return AppColors.gray100;
        if (states.contains(WidgetState.pressed)) return pressed;
        return background;
      }),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? AppColors.gray400
            : foreground,
      ),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  static final _text = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size.fromHeight(44)),
    textStyle: WidgetStatePropertyAll(
      AppTypography.body2.copyWith(decoration: TextDecoration.underline),
    ),
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? AppColors.gray400
          : AppColors.gray600,
    ),
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}
