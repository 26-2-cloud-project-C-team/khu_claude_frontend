import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';

/// 넓은 화면(데스크톱 브라우저)에서도 휴대폰 너비 열로 보이도록 가운데에 가둔다.
class AppViewport extends StatelessWidget {
  const AppViewport({super.key, required this.child});

  static const maxWidth = 480.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.gray100,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: ColoredBox(color: AppColors.white, child: child),
        ),
      ),
    );
  }
}
