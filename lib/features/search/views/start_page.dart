import 'package:flutter/material.dart';

import '../../../core/models/purpose.dart';
import '../viewmodels/search_flow_view_model.dart';
import 'widgets/option_tile.dart';

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
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Text(
              '경희 공간찾기',
              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            // TODO: Lottie 히어로(350×180, 반경 20). 동작 줄이기 설정이면 마지막 프레임 정지 이미지.
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 32),
            Text('어떤 공간을 찾아 드릴까요?', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 24),
            for (final purpose in Purpose.values)
              OptionTile(
                label: purpose.label,
                selected: false,
                leading: Icon(_icons[purpose]),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  viewModel.startWithPurpose(purpose);
                  onStarted();
                },
              ),
            const SizedBox(height: 12),
            Text(
              '로그인 없이 바로 사용할 수 있어요',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
