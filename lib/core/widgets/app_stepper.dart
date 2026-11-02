import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

// 타이포 7단계의 예외다. 인원 스테퍼의 큰 숫자에만 쓰므로 AppTypography에 두지 않는다.
const _largeNumberStyle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 40,
  fontWeight: FontWeight.w700,
  height: 48 / 40,
  leadingDistribution: TextLeadingDistribution.even,
  letterSpacing: 40 * -0.03,
  color: AppColors.gray900,
);

/// 숫자를 크게 가운데 두는 스테퍼(US-01 인원).
class AppStepper extends StatelessWidget {
  const AppStepper({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.unit = '',
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 28,
      children: [
        _StepButton.large(
          icon: Icons.remove,
          label: '줄이기',
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 96),
          child: Text(
            '$value$unit',
            style: _largeNumberStyle,
            textAlign: TextAlign.center,
          ),
        ),
        _StepButton.large(
          icon: Icons.add,
          label: '늘리기',
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

/// 이름과 함께 한 줄에 들어가는 스테퍼(AD-03 테이블 수·최대 인원·충전 테이블).
class AppStepperRow extends StatelessWidget {
  const AppStepperRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.unit = '',
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: AppSpacing.cardPadding, right: 6),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.body1)),
          _StepButton.small(
            icon: Icons.remove,
            label: '$label 줄이기',
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44),
            child: Text(
              '$value$unit',
              style: AppTypography.h3,
              textAlign: TextAlign.center,
            ),
          ),
          _StepButton.small(
            icon: Icons.add,
            label: '$label 늘리기',
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton.large({
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : _size = 52,
       _iconSize = 24,
       _background = AppColors.gray100,
       _border = null;

  // 버튼은 36으로 보이지만 터치 영역 44를 확보하려고 탭 영역을 44로 둔다.
  const _StepButton.small({
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : _size = 36,
       _iconSize = 18,
       _background = AppColors.white,
       _border = const BorderSide(color: AppColors.gray200);

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double _size;
  final double _iconSize;
  final Color _background;
  final BorderSide? _border;

  @override
  Widget build(BuildContext context) {
    final border = _border;
    final enabled = onPressed != null;

    return Semantics(
      label: label,
      button: true,
      enabled: enabled,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        child: SizedBox.square(
          dimension: _size < 44 ? 44 : _size,
          child: Center(
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                color: _background,
                shape: BoxShape.circle,
                border: border == null ? null : Border.fromBorderSide(border),
              ),
              child: Icon(
                icon,
                size: _iconSize,
                color: enabled ? AppColors.gray700 : AppColors.gray400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
