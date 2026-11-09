import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../widgets/google_sign_in_button.dart';
import '../viewmodels/admin_auth_view_model.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// AD-01 관리자 로그인 화면.
///
/// accessDenied가 true이면 관리자 권한이 없는 계정 안내 화면을 표시한다.
/// Google ID 토큰을 발급받아 관리자 인증 API에 전달한다.
class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({
    super.key,
    this.accessDenied = false,
    this.email = 'minsu.lee@gmail.com',
  });

  final bool accessDenied;
  final String email;

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  static const _googleClientId =
      '273043781488-i77ccsr0tqi878plo8sa2at2o7l5c0cf.apps.googleusercontent.com';
  static Future<void>? _initialization;

  StreamSubscription<GoogleSignInAuthenticationEvent>?
  _authenticationSubscription;
  bool _googleReady = false;
  bool _isSubmitting = false;
  String? _googleError;
  String? _selectedEmail;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      _initialization ??= GoogleSignIn.instance.initialize(
        clientId: _googleClientId,
      );
      await _initialization;

      _authenticationSubscription = GoogleSignIn.instance.authenticationEvents
          .listen(_handleAuthenticationEvent, onError: _handleGoogleError);

      if (mounted) setState(() => _googleReady = true);
    } catch (_) {
      _initialization = null;
      if (mounted) {
        setState(() {
          _googleError = 'Google 로그인 초기화에 실패했습니다. 브라우저 설정을 확인해주세요.';
        });
      }
    }
  }

  Future<void> _handleAuthenticationEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    if (!mounted ||
        event is! GoogleSignInAuthenticationEventSignIn ||
        _isSubmitting) {
      return;
    }

    final user = event.user;
    final idToken = user.authentication.idToken;
    if (idToken != null && idToken.isNotEmpty) {
      try {
        final parts = idToken.split('.');

        if (parts.length == 3) {
          final payload = jsonDecode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
          ) as Map<String, dynamic>;

          final aud = payload['aud'];
          final exp = payload['exp'];

          const expectedClientId =
              '273043781488-i77ccsr0tqi878plo8sa2at2o7l5c0cf.apps.googleusercontent.com';

          debugPrint('========== Google ID Token 확인 ==========');
          debugPrint('aud: $aud');
          debugPrint('기대 Client ID 일치: ${aud == expectedClientId}');
          debugPrint('exp: $exp');

          if (exp is num) {
            final expiry = DateTime.fromMillisecondsSinceEpoch(
              exp.toInt() * 1000,
              isUtc: true,
            );

            debugPrint('만료 시각(UTC): $expiry');
            debugPrint('현재 시각(UTC): ${DateTime.now().toUtc()}');
            debugPrint('만료 여부: ${DateTime.now().toUtc().isAfter(expiry)}');
          }
        }
      } catch (e) {
        debugPrint('ID Token 정보 확인 실패: $e');
      }
    }
    if (idToken == null || idToken.isEmpty) {
      if (mounted) {
        setState(() => _googleError = 'Google ID 토큰을 발급받지 못했습니다. 다시 로그인해주세요.');
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
      _selectedEmail = user.email;
      _googleError = null;
    });

    final authViewModel = context.read<AdminAuthViewModel>();
    final succeeded = await authViewModel.signInWithGoogleIdToken(idToken);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (succeeded) {
      context.go('/admin/spaces');
    }
  }

  void _handleGoogleError(Object _) {
    if (!mounted) return;
    setState(() {
      _googleError = 'Google 로그인에 실패했습니다. 다시 시도해주세요.';
      _isSubmitting = false;
    });
  }

  @override
  void dispose() {
    _authenticationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AdminAuthViewModel>();
    final denied = widget.accessDenied || authViewModel.isAccessDenied;
    final email = _selectedEmail ?? widget.email;
    final title = denied ? '다른 계정으로 로그인해주세요' : '관리자 계정으로 로그인해주세요';
    final description = denied
        ? '이 계정은 관리자 권한이 없어요.'
        : '관리자로 등록된 Google 계정만 접속할 수 있어요.';
    final errorMessage = _googleError ?? authViewModel.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                        Text(title, style: AppTypography.h1),
                        const SizedBox(height: 8),
                        Text(description, style: AppTypography.body2),
                        if (denied) ...[
                          const SizedBox(height: 24),
                          _AccountCard(email: email),
                          const SizedBox(height: 12),
                          Text(
                            '관리자 명단에 등록된 계정으로 다시 로그인해주세요.',
                            style: AppTypography.caption,
                          ),
                        ],
                        const Spacer(),
                        _buildGoogleButton(),
                        if (errorMessage != null || _googleError != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            errorMessage ?? _googleError!,
                            textAlign: TextAlign.center,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
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

  Widget _buildGoogleButton() {
    if (!kIsWeb) {
      return const Text('관리자 Google 로그인은 웹 브라우저에서 이용할 수 있습니다.');
    }

    if (!_googleReady) {
      if (_googleError != null) {
        return const SizedBox.shrink();
      }

      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return IgnorePointer(
      ignoring: _isSubmitting,
      child: Opacity(
        opacity: _isSubmitting ? 0.55 : 1,
        child: buildGoogleSignInButton(),
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
        const Icon(Icons.location_on, color: AppColors.primary, size: 18),
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
              child: _PhotoCard(icon: Icons.apartment),
            ),
          ),

          Positioned(
            right: 18,
            top: 38,
            child: Transform.rotate(
              angle: 0.10,
              child: _PhotoCard(icon: Icons.chair_alt),
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
      child: Icon(icon, color: AppColors.gray500, size: 36),
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
              ? const Icon(Icons.check, size: 9, color: AppColors.white)
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
            child: Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('로그인한 계정', style: AppTypography.caption),
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
