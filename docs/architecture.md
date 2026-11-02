# 아키텍처

이 프로젝트의 아키텍처 기본 원칙을 정리한 문서다. 코드를 작성하거나 구조를 바꿀 때 아래 결정을 따른다.

## 프로젝트 전제

- Flutter Web 애플리케이션이고, 규모는 10~20 페이지 수준이다.
- 테스트 코드를 함께 작성하는 것을 전제로 한다.
- 아래 결정은 모두 이 전제에서 나왔다. 규모나 요구사항이 크게 바뀌면 결정도 다시 검토한다.

## 아키텍처 결정 요약

| 항목 | 결정 |
| --- | --- |
| 프로젝트 구성 | Feature-first |
| 아키텍처 | 경량 MVVM (View / ViewModel / Repository) |
| 상태 관리 | `ChangeNotifier` + `provider` |
| 의존성 주입 | 생성자 주입, 주입 경로는 `provider` |
| 데이터 접근 | Repository 패턴 (interface + implementation) |
| 라우팅 | `go_router` |
| HTTP | `http` 또는 `dio` |
| 테스트 | Unit + Widget + 핵심 사용자 흐름만 Integration |
| Mock/Fake | 수동 Fake 우선, 필요할 때만 `mocktail` |
| Clean Architecture | 전면 적용하지 않음 |
| UseCase 계층 | 실제로 필요해질 때 추가 |

### 1. 경량 MVVM을 쓰고, Clean Architecture는 전면 적용하지 않는다

- 의도: UI와 비즈니스 로직을 분리해서 각각 독립적으로 테스트하려는 것이다. Flutter 공식 아키텍처 가이드도 MVVM과 View/ViewModel 분리 테스트를 권장한다.
- 맥락: 10~20 페이지 규모에서 UseCase, Domain Entity, Repository Interface/Impl을 전 계층에 빠짐없이 만들면 파일 수만 늘고 얻는 게 적다. 분리와 테스트 가능성은 MVVM만으로 충분히 확보된다.
- 계층별 책임과 테스트 방식:

| 계층 | 책임 | 테스트 |
| --- | --- | --- |
| View | 화면 렌더링, 사용자 입력을 ViewModel로 전달 | Widget Test |
| ViewModel | 화면 상태, 입력 검증, 액션 처리, 로딩/에러 상태 | Unit Test |
| Repository | 데이터 조회·저장, 캐싱, 데이터 변환 | Unit Test |
| API Client / Storage | HTTP 요청, 브라우저 저장소 등 외부 시스템 접근 | Unit Test |
| Model | 데이터 구조, 순수 계산·검증 | Unit Test |

### 2. ViewModel은 Flutter 렌더링 환경에 의존하지 않는다

- 의도: ViewModel을 일반 Dart 객체처럼 생성해서 Unit Test로 검증하기 위해서다.
- 규칙: ViewModel에서 `BuildContext`, `Navigator`, `ScaffoldMessenger`, Widget을 쓰지 않는다. 화면 이동이나 스낵바 표시는 ViewModel이 결과(성공 여부, 상태 값)만 돌려주고 View가 처리한다.
- `TextEditingController`, `FocusNode`, 애니메이션 컨트롤러처럼 UI 전용 상태는 View가 관리해도 된다. 반면 입력값 유효성 검증은 ViewModel이나 순수 Dart 함수로 둔다. 검증 로직이 Widget 안에 있으면 Widget Test로만 확인할 수 있어서다.

### 3. 상태 관리는 `ChangeNotifier` + `provider`로 한다

- 의도: 이 규모에서 필요한 건 "상태가 바뀌면 화면을 다시 그린다" 정도다. `ChangeNotifier`는 Flutter SDK에 내장되어 있어서 별도 프레임워크 없이 해결된다.
- 맥락: Riverpod, Bloc은 학습 비용과 boilerplate에 비해 이 규모에서 얻는 이점이 크지 않다고 판단했다. 상태 관리가 실제 병목이 되면 그때 재검토한다.
- `provider`는 ViewModel을 Widget 트리에 제공하는 용도로만 쓴다. 의존성 자체는 생성자로 받는다. 테스트에서 Fake를 생성자에 바로 넣을 수 있어야 하기 때문이다.

### 4. ViewModel은 Repository interface에만 의존한다

- 의도: 테스트에서 실제 네트워크 대신 Fake Repository를 주입하기 위해서다. 테스트가 HTTP 서버, 브라우저, 네트워크 상태에 영향을 받지 않는다.
- interface(`abstract class`)는 Repository 계층에만 둔다. 다른 계층에 습관적으로 interface를 만들지 않는다.

### 5. Fake를 우선 쓰고 mocking 라이브러리는 필요할 때만 쓴다

- 의도: 수동 Fake는 "정해진 결과를 돌려주는 구현체"라 읽기 쉽고, 여러 테스트에서 재사용된다. 호출 횟수·인자 검증처럼 Fake로 표현하기 번거로운 경우에만 `mocktail`을 쓴다.

### 6. 테스트는 목적별로 나눈다

- ViewModel Unit Test는 상태가 올바르게 바뀌는지 검증한다.
- View Widget Test는 그 상태가 화면에 올바르게 표현되는지 검증한다. ViewModel에 Fake Repository를 주입해 원하는 상태를 만든다. `go_router`를 쓰는 화면은 테스트용 Router를 주입한다.
- Integration Test는 로그인, 주요 화면 이동 같은 핵심 사용자 흐름 몇 개만 실제 브라우저에서 검증한다. 모든 흐름을 E2E로 덮으려 하지 않는다. 느리고 깨지기 쉬워서다.
- CI에서 `flutter analyze`와 `flutter test`를 돌린다.

## 폴더 구조

```
lib/
├── main.dart
├── app.dart
├── app/
│   ├── router.dart
│   └── dependencies.dart
├── core/
│   ├── network/
│   │   └── api_client.dart
│   ├── errors/
│   │   └── app_exception.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── widgets/
│       ├── app_button.dart
│       └── loading_indicator.dart
└── features/
    ├── auth/
    │   ├── models/
    │   │   └── user.dart
    │   ├── data/
    │   │   ├── auth_repository.dart
    │   │   └── auth_repository_impl.dart
    │   ├── viewmodels/
    │   │   └── login_view_model.dart
    │   └── views/
    │       ├── login_page.dart
    │       └── widgets/
    │           └── login_form.dart
    ├── dashboard/
    │   ├── viewmodels/
    │   │   └── dashboard_view_model.dart
    │   └── views/
    │       └── dashboard_page.dart
    └── settings/
        ├── viewmodels/
        │   └── settings_view_model.dart
        └── views/
            └── settings_page.dart

test/
├── core/
│   └── network/
│       └── api_client_test.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository_test.dart
│   │   ├── viewmodels/
│   │   │   └── login_view_model_test.dart
│   │   └── views/
│   │       └── login_page_test.dart
│   ├── dashboard/
│   │   ├── viewmodels/
│   │   │   └── dashboard_view_model_test.dart
│   │   └── views/
│   │       └── dashboard_page_test.dart
│   └── settings/
│       └── ...
├── helpers/
│   └── pump_test_app.dart
└── fakes/
    └── fake_auth_repository.dart

integration_test/
└── main_flow_test.dart

test_driver/
└── integration_test.dart
```

### 디렉터리별 역할

- `lib/main.dart`, `lib/app.dart`: 앱 진입점과 최상위 Widget(`MaterialApp.router` 구성)이다.
- `lib/app/`: 앱 전체를 조립하는 코드다. `router.dart`에 `go_router` 경로를 정의하고, `dependencies.dart`에서 API Client, Repository 구현체를 생성해 `provider`로 연결한다. 어떤 구현체를 쓸지는 이곳에서만 결정한다.
- `lib/core/`: 둘 이상의 Feature가 실제로 공유하는 것만 둔다. 네트워크 클라이언트, 공통 예외, 테마, 공통 Widget이 여기에 해당한다. "나중에 쓸 것 같은" 유틸리티를 미리 넣지 않는다. core가 잡동사니 창고가 되면 Feature 간 결합이 보이지 않게 늘어난다.
- `lib/features/<feature>/`: 기능 단위 묶음이다. 내부는 계층별로 나눈다.
  - `models/`: 이 Feature의 데이터 구조와 순수 계산·검증 로직
  - `data/`: Repository interface와 구현체. 파일명은 `xxx_repository.dart`(interface), `xxx_repository_impl.dart`(구현)로 짓는다.
  - `viewmodels/`: 화면별 ViewModel. 보통 페이지 하나에 ViewModel 하나다.
  - `views/`: 페이지 Widget. 페이지 안에서만 쓰는 하위 Widget은 `views/widgets/`에 둔다.
- `test/`: `lib/`의 구조를 그대로 따른다. `lib/features/auth/viewmodels/login_view_model.dart`의 테스트는 `test/features/auth/viewmodels/login_view_model_test.dart`에 있어야 한다. 구현과 테스트의 대응이 경로만으로 드러나게 하려는 것이다.
- `test/fakes/`: 여러 테스트에서 공유하는 Fake 구현체. 이름은 `Fake` 접두사를 붙인다(`FakeAuthRepository`).
- `test/helpers/`: 테스트용 앱 래핑(`MaterialApp`, Provider, 테스트 Router 주입 등) 같은 공통 셋업.
- `integration_test/`: 핵심 사용자 흐름만 담는 브라우저 통합 테스트. 실행 방법은 루트 `README.md`에 있다.
- `test_driver/`: `flutter drive`가 Integration Test를 Chrome에서 돌릴 때 쓰는 진입점. 내용은 바꿀 일이 없다.

### Feature를 나누는 기준

- Feature는 페이지가 아니라 기능 단위다. 로그인, 회원가입, 비밀번호 재설정은 모두 `auth` 하나에 넣는다. 대시보드와 설정처럼 관심사가 다르면 별도 Feature로 나눈다. 페이지마다 Feature를 만들면 같은 Repository와 Model이 여러 곳에 흩어진다.
- 모든 Feature가 같은 하위 폴더를 가질 필요는 없다. 데이터 접근이 없으면 `data/`를 만들지 않고, 정적 페이지라면 `views/`만 있어도 된다. 빈 폴더나 형식적인 파일을 구조 통일을 위해 만들지 않는다.

## 의존성 규칙

폴더를 나누는 것만으로는 분리가 유지되지 않는다. 아래 방향을 지킨다.

- `views/` → `viewmodels/` 참조 가능
- `viewmodels/` → `data/`의 Repository interface, `models/` 참조 가능
- `data/` → `views/`, `viewmodels/` 참조 금지
- ViewModel은 Repository 구현체(`*_impl.dart`)를 직접 import하지 않는다. 구현체 연결은 `lib/app/dependencies.dart`에서만 한다.
- Repository는 `isLoading`, `selectedTab` 같은 UI 상태를 갖지 않는다. UI 상태는 ViewModel의 몫이다.
- 다른 Feature의 내부(`viewmodels/`, `views/`)를 직접 참조하지 않는다. 여러 Feature가 공유해야 하는 것이 생기면 `core/`로 올릴지 검토한다.

## 복잡도가 커질 때

- ViewModel이 비대해지면 계층을 새로 만들기 전에 순수 Dart 함수나 별도 서비스 클래스로 로직을 추출하는 것부터 한다.
- `usecases/`, `domain/services/` 같은 계층은 여러 ViewModel이 같은 비즈니스 로직을 공유하고, 그 로직이 충분히 복잡해졌을 때 추가한다. 미리 만들지 않는다.

## 참고 문서

- [Flutter 공식 아키텍처 권장사항](https://docs.flutter.dev/app-architecture/recommendations)
- [Flutter 계층별 테스트 예제](https://docs.flutter.dev/app-architecture/case-study/testing)
