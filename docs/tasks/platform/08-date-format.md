# 08 날짜·시각 포맷 유틸

## 목표

API의 날짜·시각 형식을 화면 표기로 바꾸는 순수 Dart 함수를 만든다.

## 결정

OpenAPI 명세(`/api-docs/openapi.yaml`)를 기준으로 범위를 다시 정했다.

- 날짜만 있는 필드(`YYYY-MM-DD`)는 명세에 없다. 일시는 모두 offset이 붙은 ISO 8601(`2026-10-23T14:20:00+09:00`)이다
- 일시는 별도 파서 없이 `DateTime.parse`로 읽는다. offset이 있으면 UTC로 바뀌지만, `formatDate`가 UTC 기준으로 KST(+9)를 계산하므로 기기 시간대와 상관없이 같은 날짜가 나온다
- `searchedAt`은 받은 값을 그대로 다시 보내므로 포맷하지 않는다
- 이용 시간(`rules.hours`)은 30분 단위 `HH:mm`이고, 24시간 운영은 서버가 `00:00`–`24:00`으로 준다. 자정을 넘기는 시간은 받은 그대로(`22:00 – 02:00`) 쓴다

## 할 일

- [x] `lib/core/utils/date_format.dart`의 `formatDate`: KST 기준 `YYYY.MM.DD`, 시각은 보여주지 않는다
- [x] 같은 파일의 `formatHours`: `09:00 – 22:00`. 24시간(`00:00`–`24:00`, `open == close`)은 `00:00 – 24:00`

## 완료 조건

- 시간대가 다른 환경, 자정 넘김, 24시간 경우를 포함한 Unit Test가 있다

## 참고

- `docs/design-system.md` 타이포 위계(날짜 규칙)
- OpenAPI 명세 `components.schemas.Rules`의 `hours`
