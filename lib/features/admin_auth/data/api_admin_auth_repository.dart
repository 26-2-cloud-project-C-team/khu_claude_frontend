import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../models/admin_user.dart';
import 'admin_auth_repository.dart';

class ApiAdminAuthRepository implements AdminAuthRepository {
  ApiAdminAuthRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<AdminUser> signInWithGoogleIdToken(String idToken) async {
    if (idToken.trim().isEmpty) {
      throw const FormatException('Google ID 토큰이 비어 있습니다.');
    }

    final response = await _apiClient.post(
      '/api/admin/auth/google',
      body: {'idToken': idToken},
    );
    return AdminUser.fromEnvelope(response);
  }

  @override
  Future<void> signOut() async {
    await _apiClient.post('/api/admin/auth/logout');
  }

  @override
  Future<AdminUser?> fetchCurrentAdmin() async {
    try {
      final response = await _apiClient.get('/api/admin/me');
      return AdminUser.fromEnvelope(response);
    } on AppException catch (error) {
      if (error.statusCode == 401) return null;
      rethrow;
    }
  }
}
