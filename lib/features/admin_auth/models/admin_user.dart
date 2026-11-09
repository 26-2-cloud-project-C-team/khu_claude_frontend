class AdminUser {
  const AdminUser({required this.name, required this.email});

  final String name;
  final String email;

  factory AdminUser.fromEnvelope(Object? data) {
    if (data is! Map) {
      throw const FormatException('관리자 인증 응답 형식이 올바르지 않습니다.');
    }

    final payload = data['admin'] is Map ? data['admin'] as Map : data;
    final name = payload['name'];
    final email = payload['email'];
    if (name is! String || email is! String) {
      throw const FormatException('관리자 이름 또는 이메일이 응답에 없습니다.');
    }

    return AdminUser(name: name, email: email);
  }
}
