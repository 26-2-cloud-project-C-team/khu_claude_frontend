# 13 테스트 헬퍼와 Integration Test 셋업

## 목표

B·C가 처음부터 같은 방식으로 테스트를 쓰도록 공통 셋업을 만든다.

## 할 일

- [x] `test/helpers/pump_test_app.dart`: 테마, Provider(Fake 주입), 테스트 Router로 Widget을 감싸서 띄우는 헬퍼
- [x] `test/fakes/` 규칙 예시 1개(`Fake` 접두사). 아직 실제 Repository가 없어 헬퍼 사용 예시용 `ExampleRepository`와 `FakeExampleRepository`를 두었다. 실제 Fake가 생기면 바꾼다
- [x] `integration_test/` 셋업과 Chrome에서 도는 smoke test 1개
- [x] 로컬 실행 방법(chromedriver 등)을 루트 `README.md`에 기록
- [x] CI는 지금처럼 `flutter analyze`, `flutter test`만 돌린다. Integration Test를 CI에 넣을지는 핵심 흐름이 생긴 뒤 정한다

## 완료 조건

- 헬퍼를 쓴 Widget Test 예시가 통과한다
- 로컬에서 Integration Test smoke가 통과한다

## 참고

- `docs/architecture.md` 6. 테스트는 목적별로 나눈다, 폴더 구조(`test/`, `integration_test/`)
