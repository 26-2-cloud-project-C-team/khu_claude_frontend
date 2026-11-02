# 07 공용 코드값과 표시 문구

## 목표

API는 코드만 주고받고 화면 문구는 클라이언트가 관리한다. 사용자 앱과 관리자가 함께 쓰는 코드값을 `lib/core/`에 enum으로 두고, 코드 ↔ enum 변환과 표시 문구를 함께 만든다.

## 할 일

- [ ] 공용으로 둘 코드값
  - `Purpose`: `TEAM` 팀 프로젝트·회의, `CHAT` 사담, `SOLO` 개인 작업
  - `Noise`: `QUIET` 조용함, `NORMAL` 보통, `LOUD` 시끄러움
  - `TableType`: `SEAT_1`(1) · `TABLE_2`(2) · `TABLE_4`(4) · `TABLE_6`(6) · `TABLE_8_PLUS`(8). 좌석 수 포함
  - `EntryRule`: `STUDENT_ID` 학생증 태그 출입, `OPEN` 자유 출입. 나머지는 미정
  - `PhotoTag`: `ENTRANCE`, `HALLWAY`, `INSIDE`, 태그 없음(`null`)
- [ ] 한 Feature만 쓰는 코드값은 해당 Feature에 둔다(`Requirement`·`SortKey`는 B, `ReinspectionCategory`·`ReinspectionStatus`·`AdminSpaceFilter`는 C)
- [ ] 별점 문구: 1 아쉬워요 / 2 그저 그래요 / 3 괜찮아요 / 4 만족해요 / 5 최고예요
- [ ] 모르는 코드가 내려오면 예외를 던지지 않고 enum별 기본값으로 바꾼다(예: `NoiseLevel` → `NORMAL`, `ReinspectionCategory` → `ETC`). 기본값 목록은 API 명세 C1 공통 규칙의 '스키마와 이력' 탭에 있다

## 완료 조건

- 모든 코드의 왕복 변환과 표시 문구에 대한 Unit Test가 있다

## 확인 필요

- `PhotoTag.HALLWAY`의 표시 문구. 설계서 AD-03은 '가는 길', US-04·US-06은 '복도'다
- `ReinspectionCategory.ENTRY`의 표시 문구. API 명세는 '출입 규칙', 설계서 US-07 C는 '이용 안내'다(C에 전달)
- enum 이름과 코드값이 현재 API 명세와 같은지. 명세는 소음을 `NoiseLevel`로 부르는데 이 문서는 `Noise`다

## 참고

- API 명세 C1 공통 규칙. 이전 명세의 '2장 코드값'이 새 명세의 어느 페이지로 옮겨졌는지는 확인이 필요하다
