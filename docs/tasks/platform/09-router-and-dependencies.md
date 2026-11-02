# 09 라우터 골격

## 목표

B·C가 서로의 코드를 참조하지 않고도 화면을 연결할 수 있도록 경로와 이름을 먼저 정한다.

## 결정

- URL은 hash 방식(`/#/admin/spaces/3`)이다. Flutter Web 기본값이라 따로 설정하지 않는다. `#` 뒤는 서버로 가지 않으므로 배포 서버에 경로 fallback 설정이 필요 없다. path 방식으로 바꾸려면 `usePathUrlStrategy()`를 호출하고 서버가 모르는 경로에 `index.html`을 돌려주게 하면 된다
- 검색 조건은 URL에 담지 않고 사용자 화면 전체가 공유하는 `SearchFlowViewModel`에 둔다. 새로고침하면 조건이 사라지고 US-00부터 다시 시작한다(US-01 Check Point '조건은 저장하지 않는다'와 같다)
- 페이지는 라우터를 모른다. 화면 이동은 페이지 콜백으로 넘기고, `router.dart`의 builder에서 콜백에 `context.go`·`push`·`pop`을 연결한다
- `dependencies.dart`는 연결할 API Client가 생기는 06에서 만든다

## 할 일

- [x] `lib/app/router.dart`: 사용자·관리자(`/admin/…`) 경로 분리, 경로 상수 `AppRoutes`
- [x] 각 경로에 임시 페이지를 둔다. B·C의 페이지 파일과 겹치지 않도록 `router.dart` 안의 private 위젯으로 두고, 담당자가 builder를 실제 페이지로 바꾼다
  - 사용자(`ShellRoute`로 묶음): 시작 `/`, 검색 조건 `/search`, 출발 건물 선택 `/search/building`, 후보 상세 `/search/candidates`, 결과 없음 `/search/no-result`, 길찾기·이용 중 `/directions`, 이용 의견 `/directions/review`, 재조사 요청 `/directions/reinspection`, 완료 `/done`
  - 관리자: 로그인 `/admin/login`, 공간 목록 `/admin/spaces`, 등록 `/admin/spaces/new`, 공간 상세·재조사 처리 `/admin/spaces/:spaceId`, 수정 `/admin/spaces/:spaceId/edit`
- [x] 화면 간 넘겨줄 값
  - 사용자: 검색 조건과 결과는 `SearchFlowViewModel`이 들고 있고, 후보처럼 화면 하나에만 필요한 값은 `extra`로 넘긴다. 새로고침으로 값이 사라진 화면은 US-00으로 보낸다(B가 `ShellRoute`의 redirect에 추가)
  - 관리자: 공간은 경로의 `spaceId`로 가리킨다. 새로고침해도 같은 공간이 열린다
- [x] `SearchFlowViewModel`을 제공할 자리: 사용자 `ShellRoute`의 builder
- [x] 관리자 로그인 가드가 들어갈 `redirect` 자리: `/admin` 경로의 redirect. 하위 경로 전체에 적용된다(가드 구현은 C)

## 완료 조건

- 모든 경로가 임시 페이지로 열린다
- 라우터 경로에 대한 Widget Test가 있다

## 참고

- `docs/architecture.md` 디렉터리별 역할(`lib/app/`), 의존성 규칙
- `docs/tasks/README.md` B·C 작업 목록
