import '../models/admin_user.dart';

abstract class AdminAuthRepository {
  /// Google ID 토큰을 서버에 보내 관리자 세션 쿠키를 발급받는다.
  Future<AdminUser> signInWithGoogleIdToken(String idToken);

  /// HttpOnly 세션 쿠키로 현재 관리자 세션을 확인한다.
  /// 세션이 없으면 null을 반환한다.
  Future<AdminUser?> fetchCurrentAdmin();

  /// 서버 세션 쿠키를 만료 처리한다.
  Future<void> signOut();
}
