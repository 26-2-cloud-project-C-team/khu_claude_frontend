import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../data/admin_auth_repository.dart';
import '../models/admin_user.dart';

class AdminAuthViewModel extends ChangeNotifier {
  factory AdminAuthViewModel({
    required AdminAuthRepository repository,
    required ApiClient apiClient,
  }) {
    return AdminAuthViewModel._(repository: repository, apiClient: apiClient);
  }

  AdminAuthViewModel._({
    required this._repository,
    required ApiClient apiClient,
  }) {
    _unauthorizedSubscription = apiClient.adminUnauthorized.listen((_) {
      // 첫 방문 시 GET /api/admin/me의 401은 로그인되지 않은 정상 상태다.
      // 세션 복구가 끝난 뒤 기존 관리자 세션에서 발생한 401만 만료로 처리한다.
      if (_isCheckingSession || _admin == null) return;
      _admin = null;
      _errorMessage = '관리자 세션이 만료되었습니다. 다시 로그인해주세요.';
      notifyListeners();
    });
  }

  final AdminAuthRepository _repository;
  late final StreamSubscription<void> _unauthorizedSubscription;

  AdminUser? _admin;
  bool _isCheckingSession = true;
  bool _isSigningIn = false;
  String? _errorMessage;
  bool _isAccessDenied = false;
  bool _hasRestoredSession = false;

  AdminUser? get admin => _admin;
  bool get isAuthenticated => _admin != null;
  bool get isCheckingSession => _isCheckingSession;
  bool get isSigningIn => _isSigningIn;
  String? get errorMessage => _errorMessage;
  bool get isAccessDenied => _isAccessDenied;

  Future<void> restoreSession() async {
    if (_hasRestoredSession) return;
    _hasRestoredSession = true;
    _isCheckingSession = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _admin = await _repository.fetchCurrentAdmin();
    } on AppException catch (error) {
      _admin = null;
      _errorMessage =
          error.message ??
          (error.isNetworkError
              ? '인증 서버에 연결할 수 없습니다. 서버 실행 상태를 확인해주세요.'
              : '관리자 세션을 확인하지 못했습니다.');
    } catch (_) {
      _admin = null;
      _errorMessage = '관리자 세션을 확인하지 못했습니다.';
    } finally {
      _isCheckingSession = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogleIdToken(String idToken) async {
    if (_isSigningIn) return false;

    _isSigningIn = true;
    _errorMessage = null;
    _isAccessDenied = false;
    notifyListeners();

    try {
      _admin = await _repository.signInWithGoogleIdToken(idToken);
      return true;
    } on AppException catch (error) {
      _admin = null;
      _isAccessDenied = error.statusCode == 403;
      _errorMessage =
          error.message ??
          switch (error.statusCode) {
            401 => 'Google 인증에 실패했습니다. 다시 로그인해주세요.',
            403 => '이 Google 계정은 관리자 권한이 없습니다.',
            _ =>
              error.isNetworkError
                  ? '인증 서버에 연결할 수 없습니다. 서버 실행 상태를 확인해주세요.'
                  : '로그인에 실패했습니다. 잠시 후 다시 시도해주세요.',
          };
      return false;
    } catch (_) {
      _admin = null;
      _errorMessage = '로그인에 실패했습니다. 잠시 후 다시 시도해주세요.';
      return false;
    } finally {
      _isSigningIn = false;
      notifyListeners();
    }
  }

  /// 현재 앱 메모리의 로그인 상태만 지운다.
  /// 서버 로그아웃 API 경로는 제공된 명세에 없어 세션 쿠키 폐기는 수행하지 않는다.
  void clearLocalSession() {
    _admin = null;
    _errorMessage = null;
    _isAccessDenied = false;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null && !_isAccessDenied) return;
    _errorMessage = null;
    _isAccessDenied = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _unauthorizedSubscription.cancel();
    super.dispose();
  }
}
