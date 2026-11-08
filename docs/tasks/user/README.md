# 사용자 화면(US-00 ~ US-08) 작업

담당: ZHANG XUANYU. 마감 11/8.

`docs/architecture.md`를 따른다. 기반 구조(A)가 들어오기 전에 Model · Repository interface · ViewModel · Unit Test를 먼저 만들고, A의 디자인 토큰·공통 컴포넌트·단계형 레이아웃·라우터가 머지되면 View를 붙인다.

## Feature 구성

| Feature | 화면 | ViewModel |
| --- | --- | --- |
| `search` | US-00 시작, US-01·02 검색 조건 5단계, US-03 출발 건물 선택, US-04 후보 상세, US-05 결과 없음 | `SearchFlowViewModel`(퍼널 전체 공유), `CandidateViewModel`, `NoResultViewModel` |
| `directions` | US-06 A 이동 중, B 건물 도착, C 이용 중 | `DirectionsViewModel` |
| `feedback` | US-07 이용 의견·재조사 요청, US-08 완료 | `ReviewViewModel`, `ReinspectionViewModel` |

```
lib/
├── core/
│   ├── location/                           # 위치 권한·조회·10초 갱신 (search, directions 공용), 브라우저 구현
│   └── utils/geo.dart                      # 직선거리, 도보 시간(분속 70m), Building.point
└── features/
    ├── search/
    │   ├── models/      # SearchCondition, Origin, Requirement, SortKey, SearchResult, CandidateDetail, ConditionAlternative
    │   ├── data/        # SearchRepository (U1·U2·U3)
    │   └── viewmodels/
    ├── directions/
    │   ├── models/      # WalkingRoute, DirectionsStage
    │   ├── data/        # DirectionsRepository (U8)
    │   └── viewmodels/
    └── feedback/
        ├── models/      # 별점 문구·글자 수 제한, ReinspectionCategory
        ├── data/        # FeedbackRepository (U5·U6·U7)
        └── viewmodels/
```

각 Feature에는 `views/`(페이지)도 있다. 코드값과 공용 모델(`Purpose`, `NoiseLevel`, `SpacePhoto`, `ReinspectionCategory`, `Building`, 별점 문구)은 `core/models`의 A-07·A-10 정의를 쓴다. `*_repository_impl.dart`는 A-06 `ApiClient`로 API 명세(Ready, 확정)의 U1~U7을 구현한다.

## 페이지와 라우터 연결

페이지는 라우터를 모른다. ViewModel은 생성자로 받고 `ListenableBuilder`로 그리며, 화면 이동은 모두 콜백으로 밖에 넘긴다. A-09 `router.dart`에서 콜백에 `context.go` · `push` · `pop`을 연결한다.

| 페이지 | 받는 ViewModel | 콜백 → 이동 |
| --- | --- | --- |
| `StartPage` (US-00) | `SearchFlowViewModel` | `onStarted` → 검색 조건 |
| `SearchStepsPage` (US-01·02) | `SearchFlowViewModel` | `onChooseBuilding(locationUnavailable)` → US-03 push · `onSearched(result)` → 비면 US-05, 아니면 US-04 · `onExit` → 조건 시트에서 왔으면 pop, 아니면 US-00 |
| `BuildingSelectPage` (US-03) | `SearchFlowViewModel` | `onSelected` · `onLocated` → pop(검색 조건으로) · `onBack` → 위치 없음 상태면 US-00, 아니면 pop |
| `CandidatePage` (US-04) | `CandidateViewModel(result)` | `onEditStep(step)` → `flow.editFromSheet(step)` 후 검색 조건 · `onGo(candidate)` → US-06 · `onClose` → `flow.reset()` 후 US-00 · `onOpenPhoto` → A-11 |
| `CandidatePage.restored` (US-04 ③) | `CandidateViewModel.restored(spaceId)` | 공유 링크 · 앱 다시 열기 · 검색 결과 없이 US-06에서 돌아왔을 때. `onGo(candidate)` → US-06(출발점 없이) · `onClose`(닫기 · 스와이프 · '처음부터 다시 찾기') → US-00 · `onUnavailable` → US-00으로 보내며 `spaceUnavailableMessage` 토스트 |
| `NoResultPage` (US-05) | `NoResultViewModel(result)`(0곳 결과) | `onAdopt(result)`(고른 대안으로 다시 검색한 결과) → `flow.adopt(result)` 후 US-04 · `onRestart` → `flow.reset()` 후 US-00 |
| `DirectionsPage` (US-06) | `DirectionsViewModel(origin, destination)` | `onChooseOrigin` → US-03을 띄우고 고른 건물(닫으면 null)을 돌려줌 · `onReview` → US-07 A 모달 · `onReinspect` → US-07 C 모달 · `onClose` → `flow.reset()` 후 US-00. 복구로 들어오면 `origin`을 null로 넘긴다. 현재 위치 → US-03 순으로 다시 구하고, 그래도 없으면 ②(핀만 있는 지도 + 내부 안내). ②에서 뒤로가기는 US-04 ③ |
| `ReviewPage` · `ReinspectionPage` (US-07) | 열 때마다 새로 생성 | `onDone` → US-08 · `onClose` → 모달 닫기 |
| `DonePage` (US-08) | — | `onConfirm` → `flow.reset()` 후 US-00 |

화면은 `core/theme`의 토큰과 `core/widgets`의 공통 컴포넌트(`AppStepScaffold`·`AppOptionRow`·`AppChip`·`AppStepper`·`AppButton`·`AppCtaArea`·`AppBadge`·`AppRating*`·`AppTextField`·`AppCard`·`showAppBottomSheet`)로 그린다. 공통 컴포넌트에 없는 모양(US-00 아이콘 목적 타일, US-05 후보 수 배지가 붙은 대안 행, US-04 다음 후보 카드 등)은 같은 토큰으로 페이지 안에 private 위젯으로 둔다. 날짜 포맷은 A-08(`TODO(A-08)`), 지도는 A-12(`TODO(A-12)`)가 들어오면 교체한다.

라우터 연결은 `lib/app/user_routes.dart`에 있고 `router.dart`의 사용자 `ShellRoute`가 쓴다. Repository 구현체는 `dependencies.dart`에서 Provider로 연결한다.

- `SearchFlowViewModel`은 `SearchFlowHolder`가 들고 있다. go_router의 redirect가 ShellRoute 바깥 context에서 돌기 때문이다. 검색 조건이 없는 경로(새로고침)는 US-00으로 보낸다.
- 페이지별 ViewModel은 `ViewModelScope`가 만들고 페이지가 사라질 때 버린다. 페이지가 `initState`에서 바로 불러오기를 시작해 알림을 보내므로 Provider로 감싸지 않는다.
- 복구 URL은 API 명세 U3의 `/spaces/{spaceId}`다(US-04 ③). 404면 US-00으로 보내며 '지금은 볼 수 없는 공간이에요' 토스트를 띄운다. 길찾기 · 의견 화면은 `extra`로 공간을 받으므로 새로고침하면 US-00으로 간다.
- 로컬에서 배포된 API로 확인하려면 `web_dev_config.yaml`의 `target`을 `https://cloud-project.kro.kr/`로 바꿔 띄운다(커밋하지 않는다).

## 화면 연결 방식

- `SearchFlowViewModel`은 US-00부터 US-05까지 한 인스턴스를 공유한다. 라우터에서 사용자 경로를 `ShellRoute`로 묶고 그 위에서 `ChangeNotifierProvider`로 제공한다. 페이지마다 만들면 뒤로가기 때 값이 사라진다.
- `CandidateViewModel`·`NoResultViewModel`은 검색 결과를 받아 각 페이지에서 새로 만든다. U2가 전체 후보의 상세와 0곳일 때의 대안을 한 번에 주므로, 이전 · 다음 이동에는 다시 부르지 않는다. U3는 복구(US-04 ③)에만 쓴다.
- ViewModel은 화면을 옮기지 않는다. 반환값을 보고 View가 이동한다.
  - `search()` 결과가 비면 US-05, 아니면 US-04
  - `back()`이 false면 퍼널을 닫는다
  - `ReviewViewModel.submit()` · `ReinspectionViewModel.submit()`이 true면 US-08
- US-08 '확인'과 시스템 뒤로가기는 `SearchFlowViewModel.reset()` 후 US-00으로 보낸다.

## 진행 순서

| 시기 | 작업 |
| --- | --- |
| ~11/3 | Model · Repository interface · ViewModel · View(임시 컴포넌트) · Fake · Unit/Widget Test (이 문서와 함께 들어옴) |
| A 머지 후 ~11/6 | 임시 컴포넌트를 A 공통 컴포넌트·토큰으로 교체(완료), 시안과 여백 맞추기 |
| API 명세 확정 후 ~11/8 | `*_repository_impl.dart`를 A-06 ApiClient로 구현하고 `dependencies.dart`에 연결, `router.dart`에 페이지·콜백 연결(완료) |
| 마지막 | US-06 지도를 A-12 카카오맵 래퍼에 연결 |

## 확인 필요

1. '지금 이용 가능' 배지는 API에 따로 없어 `rules.hours`와 KST 현재 시각으로 판단한다. 서버 기준이 따로 있으면 맞춘다.
2. `tasks/README.md`에서 US-06 C · US-07이 C(관리자·의견) 목록에 있다. 사용자 화면이라 이쪽에서 맡는 것으로 정리할지 확인한다.
3. 재조사 결과 Q&A의 질문 줄은 API에 문구가 없어 항목 이름으로 'Q. 이용 시간 · 분위기 제보'처럼 만든다.
4. 길찾기 지도(A-12 `AppMap`)는 아직 연결하지 않았다. US-06은 지도 자리에 안내 문구를 둔다.
