import 'package:flutter/material.dart';

import '../../../core/models/purpose.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../viewmodels/search_flow_view_model.dart';

/// US-00 시작 화면. 목적 타일이 곧 시작 버튼이다.
class StartPage extends StatelessWidget {
  const StartPage({super.key, required this.viewModel, required this.onStarted});

  final SearchFlowViewModel viewModel;

  /// 목적을 고른 뒤 검색 조건 퍼널(US-01 출발점)로 보낸다.
  final VoidCallback onStarted;

  static const _icons = {
    Purpose.team: Icons.groups_outlined,
    Purpose.chat: Icons.forum_outlined,
    Purpose.solo: Icons.laptop_mac_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.cardPadding,
          ),
          children: [
            Text('경희 공간찾기', style: AppTypography.label.copyWith(color: AppColors.primary)),
            const SizedBox(height: AppSpacing.belowTitle),
            // TODO: Lottie 히어로(350×180, 반경 20). 동작 줄이기 설정이면 마지막 프레임 정지 이미지.
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            const Text('어떤 공간을 찾아 드릴까요?', style: AppTypography.h1),
            const SizedBox(height: AppSpacing.belowTitle),
            for (final purpose in Purpose.values) ...[
              _PurposeTile(
                label: purpose.label,
                icon: _icons[purpose]!,
                onTap: () {
                  viewModel.startWithPurpose(purpose);
                  onStarted();
                },
              ),
              const SizedBox(height: AppSpacing.between),
            ],
            Text(
              '로그인 없이 바로 사용할 수 있어요',
              textAlign: TextAlign.center,
              style: AppTypography.body2.copyWith(color: AppColors.gray600),
            ),
          ],
        ),
      ),
    );
  }
}

/// 목적 타일(아이콘 + 이름 한 줄, 높이 60). 공통 옵션 행에는 앞 아이콘이 없어
/// 같은 모양(Gray 50 바탕 · Gray 100 테두리 · 반경 14)으로 따로 둔다. 선택 상태는 없다.
class _PurposeTile extends StatelessWidget {
  const _PurposeTile({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.gray50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.option),
        side: const BorderSide(color: AppColors.gray100, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        child: SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Icon(icon, size: 24, color: AppColors.gray700),
                const SizedBox(width: AppSpacing.between),
                Expanded(
                  child: Text(label, style: AppTypography.body1.copyWith(color: AppColors.gray900)),
                ),
                const Icon(Icons.chevron_right, size: 20, color: AppColors.gray400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
