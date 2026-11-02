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
│   ├── location/location_repository.dart   # 위치 권한·조회·10초 갱신 (search, directions 공용)
│   ├── models/                             # Purpose, Noise, PhotoTag, Building — A-07·A-10이 들어오면 교체
│   └── utils/geo.dart                      # 직선거리, 도보 시간(분속 70m)
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

각 Feature에는 `views/`(페이지)도 있다. `*_repository_impl.dart`는 A-06 ApiClient와 API 명세 확정 후 만든다.

## 페이지와 라우터 연결

페이지는 라우터를 모른다. ViewModel은 생성자로 받고 `ListenableBuilder`로 그리며, 화면 이동은 모두 콜백으로 밖에 넘긴다. A-09 `router.dart`에서 콜백에 `context.go` · `push` · `pop`을 연결한다.

| 페이지 | 받는 ViewModel | 콜백 → 이동 |
| --- | --- | --- |
| `StartPage` (US-00) | `SearchFlowViewModel` | `onStarted` → 검색 조건 |
| `SearchStepsPage` (US-01·02) | `SearchFlowViewModel` | `onChooseBuilding(locationUnavailable)` → US-03 push · `onSearched(result)` → 비면 US-05, 아니면 US-04 · `onExit` → 조건 시트에서 왔으면 pop, 아니면 US-00 |
| `BuildingSelectPage` (US-03) | `SearchFlowViewModel` | `onSelected` · `onLocated` → pop(검색 조건으로) · `onBack` → 위치 없음 상태면 US-00, 아니면 pop |
| `CandidatePage` (US-04) | `CandidateViewModel(result)` | `onEditStep(step)` → `flow.editFromSheet(step)` 후 검색 조건 · `onGo(candidate)` → US-06 · `onEmpty` → US-05 · `onClose` → `flow.reset()` 후 US-00 · `onOpenPhoto` → A-11 |
| `NoResultPage` (US-05) | `NoResultViewModel(condition)` | `onAdopt(result)` → `flow.adopt(result)` 후 US-04 · `onRestart` → `flow.reset()` 후 US-00 |
| `DirectionsPage` (US-06) | `DirectionsViewModel(origin, destination)` | `onReview` → US-07 A 모달 · `onReinspect` → US-07 C 모달 · `onClose` → `flow.reset()` 후 US-00 |
| `ReviewPage` · `ReinspectionPage` (US-07) | 열 때마다 새로 생성 | `onDone` → US-08 · `onClose` → 모달 닫기 |
| `DonePage` (US-08) | — | `onConfirm` → `flow.reset()` 후 US-00 |

진행 바·옵션 행·단계형 틀(`search/views/widgets/`), 날짜 포맷, 별점 골드·Positive 색은 A-02·03·05·08이 들어오기 전까지 쓰는 임시 구현이다. `TODO(A-xx)`를 검색해 교체한다. 지도는 자리만 잡아 두었다(`TODO(A-12)`).

## 화면 연결 방식

- `SearchFlowViewModel`은 US-00부터 US-05까지 한 인스턴스를 공유한다. 라우터에서 사용자 경로를 `ShellRoute`로 묶고 그 위에서 `ChangeNotifierProvider`로 제공한다. 페이지마다 만들면 뒤로가기 때 값이 사라진다.
- `CandidateViewModel`·`NoResultViewModel`은 검색 결과를 받아 각 페이지에서 새로 만든다.
- ViewModel은 화면을 옮기지 않는다. 반환값을 보고 View가 이동한다.
  - `search()` 결과가 비면 US-05, 아니면 US-04
  - `back()`이 false면 퍼널을 닫는다
  - `CandidateViewModel.isEmpty`면 US-05
  - `ReviewViewModel.submit()` · `ReinspectionViewModel.submit()`이 true면 US-08
- US-08 '확인'과 시스템 뒤로가기는 `SearchFlowViewModel.reset()` 후 US-00으로 보낸다.

## 진행 순서

| 시기 | 작업 |
| --- | --- |
| ~11/3 | Model · Repository interface · ViewModel · View(임시 컴포넌트) · Fake · Unit/Widget Test (이 문서와 함께 들어옴) |
| A 머지 후 ~11/6 | 임시 컴포넌트를 A 공통 컴포넌트·토큰으로 교체, `router.dart`에 콜백 연결, 시안과 여백 맞추기 |
| API 명세 확정 후 ~11/7 | `*_repository_impl.dart`를 A-06 ApiClient로 구현하고 `dependencies.dart`에 연결 |
| 마지막 | US-06 지도를 A-12 카카오맵 래퍼에 연결 |

## 확인 필요

1. `Requirement`·`SortKey`·`ReinspectionCategory` 코드값과 `CandidateDetail` 필드 이름. API 명세를 보기 전에 화면 설계서 기준으로 임시로 정했다(`TODO` 표시).
2. U2가 결과 0곳일 때 대안을 함께 주는지. 지금은 `NoResultViewModel`이 대안마다 U2를 다시 불러 후보 수를 센다.
3. `tasks/README.md`에서 US-06 C · US-07이 C(관리자·의견) 목록에 있다. 사용자 화면이라 이쪽에서 맡는 것으로 정리할지 확인한다.
4. `PhotoTag.HALLWAY` 표시 문구('가는 길' / '복도'), `ReinspectionCategory.ENTRY` 표시 문구('출입 규칙' / '출입 · 취식 규칙').
5. `ReinspectionCategory`는 관리자 AD-04도 쓰므로 `core/`로 옮길지 관리자 담당과 정한다.
