# 01 폴더 구조와 패키지 세팅

## 목표

Flutter 기본 템플릿을 걷어내고, `docs/architecture.md`의 폴더 구조와 패키지 결정을 코드에 반영한다.

## 할 일

- [x] 카운터 템플릿(`lib/main.dart`의 `MyApp`, `test/widget_test.dart`) 제거
- [x] `lib/main.dart`(진입점), `lib/app.dart`(`MaterialApp.router`) 분리
- [x] `pubspec.yaml`의 `description` 정리
- [x] 패키지 추가: `provider`, `go_router`, HTTP 패키지(`http` 또는 `dio` 중 결정), dev에 `mocktail`, `integration_test`
- [x] `lib/app/`, `lib/core/`, `lib/features/`는 실제 파일이 생길 때 만든다. 빈 폴더나 형식적인 파일은 두지 않는다
- [ ] `web/index.html`, `web/manifest.json`의 앱 이름·설명을 서비스 이름으로 변경

## 완료 조건

- `flutter analyze`, `flutter test`가 통과한다
- `flutter run -d chrome`으로 빈 첫 화면이 뜬다

## 참고

- `docs/architecture.md` 아키텍처 결정 요약, 폴더 구조
