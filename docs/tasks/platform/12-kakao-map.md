# 12 카카오맵 JS SDK 연동 래퍼

## 목표

길찾기 화면(US-06)이 지도 SDK를 직접 다루지 않도록, 카카오맵 JS SDK를 감싼 지도 위젯을 `lib/core/`에 만든다.

## 결정

- 화면은 `AppMap`만 쓰고, 실제 지도는 `MapViewFactory`로 주입한다. 앱은 `dependencies.dart`에서 `KakaoMapViewFactory`를, 테스트는 `test/fakes/fake_map_view_factory.dart`의 `FakeMapViewFactory`를 `provider`로 넣는다
- 그릴 것은 `MapOverlays`(현재 위치, 목적지, 경로) 값으로 넘기고, 범위 맞추기·이동은 `onCreated`로 받은 `MapController`로 한다
- 카카오 구현은 `dart:js_interop` + `package:web`이고 조건부 import로 웹에서만 쓴다. 웹이 아닌 환경(Unit·Widget Test)에서는 안내 문구만 보인다
- JavaScript 키는 코드에 두지 않고 `--dart-define=KAKAO_MAP_KEY=…`로 넘긴다. 허용 도메인으로만 쓸 수 있는 키라 노출돼도 다른 도메인에서는 쓸 수 없지만, 키 교체가 코드 변경이 되지 않게 하려는 것이다
- 로컬 개발 서버 포트는 `3000`으로 고정한다. 콘솔에 등록하는 도메인과 맞추기 위해서다
- 목적 건물 강조는 건물 외곽 좌표가 명세에 없어서, 목적지 중심 반경 30m(도착 판정 거리)를 Primary Tint로 칠한다
- 현재 위치를 10초마다 가져오는 일은 위치 서비스(B)가 맡는다. 지도는 `currentLocation` 값이 바뀌면 점을 옮긴다

## 할 일

- [x] 카카오 개발자 앱 키 발급, 허용 도메인(로컬 `http://localhost:3000`·운영) 등록
- [x] Flutter Web에서 SDK 로드와 지도 렌더링(`HtmlElementView` + JS interop). SDK는 처음 지도를 띄울 때 한 번만 넣는다
- [x] SDK 기본 마커·경로 스타일은 쓰지 않고 오버레이로 그린다
  - 현재 위치: 경희블루 점(`CustomOverlay`)
  - 목적지: 경희레드 핀(`CustomOverlay`, SVG)
  - 경로: 경희레드 선(흰 외곽선). 굵기 9 흰 선 위에 굵기 5 빨간 선을 겹친다
- [x] 경로는 서버가 준 `path`를 그대로 그린다. `approximate: true`라 좌표가 두 개뿐이어도 두 점을 이은 직선이 된다
- [x] 출발점과 목적지가 모두 보이도록 범위 맞추기(`MapController.fitBounds`)
- [x] '현재 위치로' 되돌리기(`MapController.moveTo`)
- [x] 목적 건물 강조(Primary Tint 원)
- [x] B가 Widget Test에서 실제 SDK 없이 쓸 수 있도록 인터페이스와 Fake 제공

## 완료 조건

- 로컬에서 핀·경로·현재 위치가 지도 위에 그려진다(`tool/map_preview.dart`, README '지도' 참고)
- 래퍼 인터페이스에 대한 Fake와 그 사용 예시 테스트가 있다

## 참고

- `docs/design-system.md` Check Point 4번
- 화면 설계서 US-06
- API 명세 U7 도보 경로 조회(`GET /api/routes/walk`). `path`는 `{ "lat", "lng" }` 객체를 이동 순서대로 담은 배열이고 좌표는 2개 이상이다. 거리·소요 시간은 응답의 `distanceM`, `walkMin`을 쓴다
