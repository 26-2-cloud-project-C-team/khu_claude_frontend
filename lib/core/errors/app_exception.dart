/// API 호출 실패를 나타내는 공통 예외다.
///
/// 화면 분기는 [code]로 하고, [isServerError]·[isNetworkError]인 경우는 [code] 없이 처리한다.
class AppException implements Exception {
  const AppException({
    this.statusCode,
    this.code,
    this.message,
    this.fieldErrors = const [],
    this.retryAfter,
  });

  /// 응답을 받지 못했으면(연결 실패·타임아웃) `null`이다.
  final int? statusCode;

  /// `{도메인}_{사유}` 형식의 에러 코드. 5xx와 에러 스키마가 아닌 응답에서는 `null`이다.
  final String? code;

  /// 사용자에게 그대로 보여줄 수 있는 서버 문구. [code]가 있을 때만 오므로 화면은 기본 문구도 둔다.
  final String? message;

  final List<FieldError> fieldErrors;

  /// `429`·`503`의 `Retry-After` 헤더 값.
  final Duration? retryAfter;

  bool get isNetworkError => statusCode == null;

  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() =>
      'AppException(statusCode: $statusCode, code: $code, message: $message, '
      'fieldErrors: $fieldErrors, retryAfter: $retryAfter)';
}

class FieldError {
  const FieldError({required this.field, required this.reason});

  final String field;
  final String reason;

  @override
  bool operator ==(Object other) =>
      other is FieldError && other.field == field && other.reason == reason;

  @override
  int get hashCode => Object.hash(field, reason);

  @override
  String toString() => 'FieldError($field, $reason)';
}
