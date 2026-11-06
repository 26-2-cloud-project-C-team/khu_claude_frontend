import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.gray100,
      child: Center(child: Text(message, style: AppTypography.body2)),
    );
  }
}
