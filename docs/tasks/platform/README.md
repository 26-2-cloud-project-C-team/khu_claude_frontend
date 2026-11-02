# 기반 구조(A) 작업 목록

사용자 탐색·길찾기(B)와 관리자·의견(C)이 올라설 기반을 만든다. 번호는 `docs/tasks/README.md`의 A 목록과 같다.

## 진행 순서

B·C가 기다리지 않도록 막는 작업부터 한다.

| 순서 | 작업 | 기다리는 쪽 |
| --- | --- | --- |
| 1 | [01 폴더 구조와 패키지 세팅](01-project-setup.md) | 전체 |
| 2 | [13 테스트 헬퍼와 Integration Test 셋업](13-test-setup.md) | 전체 |
| 3 | [09 라우터 골격과 `dependencies.dart` 조립](09-router-and-dependencies.md) | B, C |
| 4 | [02 디자인 토큰](02-design-tokens.md) | B, C |
| 5 | [03 공통 컴포넌트: 버튼·옵션 행·칩·입력 필드·카드](03-common-components-basic.md) | B, C |
| 6 | [04 공통 컴포넌트: 바텀시트·상태 배지·별점·숫자 스테퍼](04-common-components-overlay.md) | B, C |
| 7 | [05 단계형 화면 레이아웃](05-step-layout.md) | B(US-01·02), C(AD-03) |
| 8 | [06 API Client와 에러 응답 파싱](06-api-client.md) | B, C의 Repository 구현체 |
| 9 | [07 공용 코드값과 표시 문구](07-shared-enums.md) | B, C |
| 10 | [08 날짜·시각 포맷 유틸](08-date-format.md) | B, C |
| 11 | [10 건물 모델과 건물 목록·검색 위젯](10-building-list.md) | B(US-03), C(AD-03) |
| 12 | [11 사진 크게 보기 화면](11-photo-viewer.md) | B(US-04), C(AD-04) |
| 13 | [12 카카오맵 JS SDK 연동 래퍼](12-kakao-map.md) | B(US-06) |

B·C는 3~10번이 끝나기 전에도 Fake Repository로 ViewModel과 Unit Test를 먼저 쓸 수 있다. 화면 작업이 막히는 건 2~7번이다.

## 먼저 정해야 할 것

| 항목 | 관련 작업 |
| --- | --- |
| HTTP 패키지(`http` / `dio`) | 01, 06 |
| 로컬 개발 서버의 `/api/…` 프록시 구성(운영은 같은 origin으로 확정) | 06 |
| URL 방식(path / hash). path면 서버가 모든 경로를 `index.html`로 돌려줘야 한다 | 09 |
| 390 너비보다 넓은 화면에서 레이아웃 | 05 |
| 카카오 개발자 앱 키와 허용 도메인 | 12 |
