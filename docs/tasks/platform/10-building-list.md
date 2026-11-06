# 10 건물 모델과 건물 목록·검색 위젯

## 목표

출발 건물 선택(US-03 B)과 공간 등록의 건물 선택 시트(AD-03)는 같은 목록이다. 모델과 목록 위젯을 `lib/core/`에 하나로 만든다.

## 결정

- `Building`은 OpenAPI 명세의 `Building` 스키마를 따른다. `id`는 UUID 문자열이고, AD-03 층 선택에 쓰는 `floorRange`가 있다
- 검색은 띄어쓰기와 영문 대소문자를 무시한다(`중앙 도서관`으로도 `중앙도서관(대학본부)`을 찾는다)
- 검색 필드는 US-03 시안대로 높이 52, 앞에 검색 아이콘이 있는 형태다. 공통 입력 필드(56)와 달라 위젯 안에 둔다
- 직선거리 같은 보조 문구는 `captionOf`로 받는다. 위치 계산은 위젯이 하지 않는다

## 할 일

- [x] `lib/core/models/building.dart`: `Building`(`id`, `name`, `lat`, `lng`, `floorRange`)과 `fromJson`. `FloorRange.floors`는 0층을 뺀 층 목록이다
- [x] `lib/core/widgets/building_list.dart`의 `BuildingList`: 상단 검색 필드 + 건물 행
  - 입력 즉시 이름으로 필터, 지우면 전체 목록
  - 가나다순
  - 행을 탭하면 `onSelected`로 선택 결과를 돌려준다. 확인 버튼은 없다
- [x] 전체 화면(US-03 B)은 `BuildingList`에 `header`·`padding`을 넣어 쓰고, 바텀시트(AD-03)는 `showBuildingSelectSheet`로 연다
- [x] 데이터 조회는 하지 않는다. 사용자는 `GET /api/buildings`(공개 공간이 있는 건물만), 관리자는 `GET /api/admin/buildings`(전체 건물)로 엔드포인트가 달라서 각 Feature의 Repository가 맡는다

## 완료 조건

- 검색 필터, 행 선택에 대한 Widget Test가 있다

## 참고

- 화면 설계서 US-03 B, AD-03 선택 시트 A
- OpenAPI 명세 `GET /api/buildings`, `GET /api/admin/buildings`, `components.schemas.Building`
