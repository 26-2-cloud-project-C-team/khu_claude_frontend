
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// AD-01 관리자 로그인 화면.
///
/// accessDenied가 true이면 관리자 권한이 없는 계정 안내 화면을 표시한다.
/// 실제 Google 인증은 추후 Repository 연결 단계에서 구현한다.
class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({
    super.key,
    this.accessDenied = false,
    this.email = 'minsu.lee@gmail.com',
  });

  final bool accessDenied;
  final String email;

  @override
  Widget build(BuildContext context) {
    final title = accessDenied
        ? '다른 계정으로 로그인해주세요'
        : '관리자 계정으로 로그인해주세요';

    final description = accessDenied
        ? '이 계정은 관리자 권한이 없어요.'
        : '관리자로 등록된 Google 계정만 접속할 수 있어요.';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AdminWordmark(),

                        const SizedBox(height: 24),

                        const _AdminIllustration(),

                        const SizedBox(height: 24),

                        Text(
                          title,
                          style: AppTypography.h1,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          description,
                          style: AppTypography.body2,
                        ),

                        if (accessDenied) ...[
                          const SizedBox(height: 24),
                          _AccountCard(email: email),
                          const SizedBox(height: 12),
                          Text(
                            '관리자 명단에 등록된 계정으로 다시 로그인해주세요.',
                            style: AppTypography.caption,
                          ),
                        ],

                        const Spacer(),

                        _GoogleLoginButton(
                          denied: accessDenied,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Google 로그인은 추후 연동 예정입니다.'),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        Text(
                          '로그인 후 관리자 등록 여부를 확인합니다.',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 관리자 페이지 워드마크
class _AdminWordmark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.location_on,
          color: AppColors.primary,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(
          '경희 공간찾기 관리자 페이지',
          style: AppTypography.label.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// 설계서에 맞춘 정적 관리자 로그인 일러스트
class _AdminIllustration extends StatelessWidget {
  const _AdminIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 18,
            top: 38,
            child: Transform.rotate(
              angle: -0.10,
              child: _PhotoCard(
                icon: Icons.apartment,
              ),
            ),
          ),

          Positioned(
            right: 18,
            top: 38,
            child: Transform.rotate(
              angle: 0.10,
              child: _PhotoCard(
                icon: Icons.chair_alt,
              ),
            ),
          ),

          Container(
            width: 174,
            height: 112,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gray900.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ChecklistRow(checked: true),
                SizedBox(height: 10),
                _ChecklistRow(checked: true),
                SizedBox(height: 10),
                _ChecklistRow(checked: true),
                SizedBox(height: 10),
                _ChecklistRow(checked: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 82,
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.white, width: 4),
      ),
      child: Icon(
        icon,
        color: AppColors.gray500,
        size: 36,
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: checked ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: checked ? AppColors.primary : AppColors.gray300,
            ),
          ),
          child: checked
              ? const Icon(
                  Icons.check,
                  size: 9,
                  color: AppColors.white,
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 7,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}

/// 권한 없는 계정 정보
class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primaryTint,
            child: Icon(
              Icons.person,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '로그인한 계정',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: AppTypography.body2.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Google 로그인 버튼
class _GoogleLoginButton extends StatelessWidget {
  const _GoogleLoginButton({
    required this.denied,
    required this.onPressed,
  });

  final bool denied;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.gray900,
          side: const BorderSide(color: AppColors.gray200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'G',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4285F4),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              denied
                  ? '다른 Google 계정으로 로그인'
                  : 'Google 계정으로 로그인',
              style: AppTypography.body1.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
