# 07 공용 코드값과 표시 문구

## 목표

API는 코드만 주고받고 화면 문구는 클라이언트가 관리한다. 사용자 앱과 관리자가 함께 쓰는 코드값을 `lib/core/`에 enum으로 두고, 코드 ↔ enum 변환과 표시 문구를 함께 만든다.

## 결정

OpenAPI 명세(`/api-docs/openapi.yaml`)를 기준으로 범위를 다시 정했다.

- 명세에서 빠진 코드값은 만들지 않는다. 테이블은 `tableCount`·`maxSeatsPerTable` 숫자로, 출입 규칙은 `isCafe`·`talkAllowed` boolean으로 바뀌었다
- 사진 태그는 코드가 아니라 `photos.entrance`·`approach`·`inside`·`extras` 필드로 구분된다. 태그 표시 문구(입구 · 가는 길 · 내부)는 사진 뷰어(11)에서 정한다
- `ReinspectionCategory`는 사용자(US-07)와 관리자(AD-04)가 함께 쓰므로 `lib/core/`에 둔다
- enum 이름은 명세 스키마 이름을 따른다(`NoiseLevel`)
- 표시 문구의 가운뎃점은 앞뒤를 띄운다(`팀 프로젝트 · 회의`)

## 할 일

- [x] `lib/core/models/`에 공용 코드값. 모두 `code`·`label`과 `fromCode`를 가진다
  - `Purpose`: `TEAM` 팀 프로젝트 · 회의, `CHAT` 사담, `SOLO` 개인 작업
  - `NoiseLevel`: `QUIET` 조용함, `NORMAL` 보통, `LOUD` 시끄러움
  - `ReinspectionCategory`: `TIME_MOOD` 이용 시간 · 분위기, `TABLE_FACILITY` 테이블 · 시설, `LOCATION_PHOTO` 위치 · 사진, `ENTRY_FOOD` 출입 · 취식 규칙, `CLOSED_MOVED` 폐쇄 · 이전, `ETC` 기타
- [x] 한 Feature만 쓰는 코드값은 해당 Feature에 둔다(`Requirement`·`SortKey`·`AlternativeType`은 B)
- [x] 별점 문구(`ratingLabel`): 1 아쉬워요 / 2 그저 그래요 / 3 괜찮아요 / 4 만족해요 / 5 최고예요
- [x] 모르는 코드는 예외를 던지지 않고 명세의 규칙대로 바꾼다
  - `Purpose` → `null`(표시하지 않음)
  - `NoiseLevel` → `NORMAL`
  - `ReinspectionCategory` → `ETC`

## 완료 조건

- 모든 코드의 왕복 변환과 표시 문구에 대한 Unit Test가 있다

## 참고

- OpenAPI 명세 `components.schemas`의 `Purpose`·`NoiseLevel`·`ReinspectionCategory`
