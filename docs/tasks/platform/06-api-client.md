# 06 API Client와 에러 응답 파싱

## 목표

B·C의 Repository 구현체가 쓰는 HTTP 클라이언트와 공통 예외를 `lib/core/network/`, `lib/core/errors/`에 만든다.

## 결정

- HTTP 패키지는 `dio`다.
- `API-Version: 1` 헤더를 모든 요청에 명시한다. 서버 기본값이 바뀌어도 응답 형식이 그대로 유지된다.
- 로컬 개발은 Flutter 웹 개발 서버의 프록시(루트 `web_dev_config.yaml`)로 `/api/…`를 API 서버에 넘긴다. API 서버 주소가 다르면 `target`만 바꾼다.
- `ApiClient`는 성공하면 디코딩한 JSON(본문이 없으면 `null`)을 돌려주고, 실패하면 `AppException`을 던진다. 응답을 받지 못한 경우는 `statusCode`가 `null`이다(`isNetworkError`).
- 5xx는 본문에 에러 스키마가 있어도 `code`를 비워 둔다. 화면은 `isServerError`로 처리한다.
- 관리자 API의 401은 `ApiClient.adminUnauthorized` 스트림으로 알린다. C가 구독해 AD-01로 보낸다. 로그인(`/api/admin/auth/google`)의 401은 Google 토큰 오류라 알리지 않는다.

## 할 일

- [x] Base URL: 운영에서는 웹과 API를 같은 origin에서 서비스하므로(Caddy가 `/api/…`만 API 서버로 프록시) 현재 origin 기준으로 `/api/…`를 호출한다. 관리자 API는 `/api/admin/…`이다
- [x] API 버전은 URL이 아니라 `API-Version` 요청 헤더로 지정한다. 생략하면 기본값 `1`이 적용되므로 명시할지 생략할지 정한다. 지원하지 않는 버전은 400 `COMMON_INVALID_API_VERSION`이다
- [x] 로컬 개발 환경 구성: 개발 서버 프록시로 `/api/…`를 API 서버에 넘겨 운영과 같은 origin 구조를 맞춘다. 세션 쿠키(`khu_sid`, `khu_admin_sid`)가 HttpOnly라 다른 origin으로 호출하면 붙지 않는다
- [x] JSON 요청·응답 처리(`Content-Type: application/json`)
- [x] 에러 응답 파싱 → 공통 예외(`AppException`)
  - 형식은 `{ "error": { "code", "message", "details" } }`이다
  - 세부 분기는 HTTP 상태 코드가 아니라 `error.code`(`{도메인}_{사유}`, 도메인은 `COMMON`·`AUTH`·`ADMIN`·`SPACE`·`BUILDING`·`REINSPECTION`)로 한다. 화면에 `message`를 그대로 띄우지 않는다
  - 필드 오류는 `error.details.fields[]`의 `field`, `reason`
  - 5xx는 본문과 상관없이 상태 코드로 처리한다. `502`·`504`는 본문이 에러 스키마가 아닐 수 있다
  - `429`·`503`의 `Retry-After` 헤더. `429`는 U5·U6의 요청 제한(세션 분당 10회, IP 분당 60회)을 넘었을 때 `COMMON_RATE_LIMITED`로 온다
- [x] 관리자 API의 `401`을 C가 받아 AD-01로 보낼 수 있도록 알림 지점 제공
- [x] `lib/app/dependencies.dart`: API Client 생성과 `provider` 연결. Repository 구현체는 B·C가 여기에 추가한다(09에서 옮겨 옴)

## 응답 처리 규칙

Repository 구현체가 응답을 모델로 바꿀 때 지킨다.

- 값이 없는 필드는 생략되지 않고 `null`로 온다. 필드가 있는지가 아니라 값이 `null`인지로 판단한다
- 모르는 응답 필드는 무시한다. 역직렬화가 실패하면 안 된다
- 사용자 익명 세션 쿠키는 U4·U5·U6에 처음 접근할 때 발급된다. U1·U2·U3·U7은 세션을 쓰지 않는다
- 요청 본문 크기 제한: JSON 1MB, 사진 10MB. 넘으면 413 `COMMON_PAYLOAD_TOO_LARGE`다. 요청 전에 클라이언트에서 먼저 검사해도 되지만 최종 검증은 서버가 한다

## 완료 조건

- 정상 응답, 에러 스키마 응답(`error.code`·필드 오류), 에러 스키마가 아닌 5xx, `Retry-After`에 대한 Unit Test가 있다

## 참고

- API 명세 C1 공통 규칙, C2 에러 코드(전체 에러 코드와 상태 코드 매핑), C3 화면별 API 호출
