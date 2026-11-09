# khu_claude_frontend

경희대학교 국제캠퍼스 공간 찾기 웹 앱(Flutter Web)이다. 구조와 규칙은 `docs/architecture.md`, `docs/design-system.md`를 따른다.

Flutter 버전은 `.fvmrc`로 고정되어 있다. 아래 명령은 fvm 기준이며, 같은 버전의 Flutter가 PATH에 있으면 `fvm`을 빼고 실행해도 된다.

## 실행

```sh
fvm flutter pub get
fvm flutter run -d chrome
```

API는 운영과 같은 origin에서 호출한다. 개발 서버가 `/api/…` 요청을 로컬 API 서버로 넘기며, 설정은 `web_dev_config.yaml`에 있다. 기본값은 `http://localhost:8080`이고, API 서버 주소가 다르면 `target`을 바꾼다.

### 지도

길찾기 지도는 카카오맵 JavaScript SDK를 쓴다. JavaScript 키를 `KAKAO_MAP_KEY`로 넘겨야 지도가 뜨고, 키가 없으면 지도 자리에 안내 문구만 나온다.

```sh
fvm flutter run -d chrome --dart-define=KAKAO_MAP_KEY=<JavaScript 키>
```

개발 서버는 `http://localhost:3000`으로 뜬다(`web_dev_config.yaml`). 이 주소가 카카오 개발자 콘솔의 JavaScript SDK 도메인에 등록되어 있어야 한다.

지도 래퍼만 따로 확인하려면 확인용 진입점을 띄운다. API 명세의 도보 경로 예시 좌표로 핀·경로·현재 위치를 그린다(실제 건물 위치와는 다르다).

```sh
fvm flutter run -d chrome -t tool/map_preview.dart --dart-define=KAKAO_MAP_KEY=<JavaScript 키>
```

## 배포

`main`에 push하면 `.github/workflows/deploy.yml`이 웹을 빌드해 운영 서버(`https://cloud-project.kro.kr`)에 올린다. 빌드 산출물은 커밋 SHA 이름으로 S3에 올라가고, 서버가 SSM 명령으로 받아 현재 버전을 교체한다. 서버 쪽 검증에 실패하면 이전 버전이 그대로 남는다.

- 저장소 secret `KAKAO_MAP_KEY`에 카카오 JavaScript 키가 있어야 한다. 없으면 빌드 전에 실패한다.
- 롤백은 Actions에서 Deploy 워크플로를 `main` 기준으로 수동 실행하면서 `version`에 이전 배포의 40자리 커밋 SHA를 넣는다. 빌드 없이 S3에 남아 있는 산출물을 다시 배포한다.

## 테스트

Unit·Widget Test는 CI에서도 돈다.

```sh
fvm flutter analyze
fvm flutter test
```

Widget Test는 `test/helpers/pump_test_app.dart`의 `tester.pumpTestApp()`으로 띄운다. 앱 테마, Provider 주입, 테스트 Router를 한 번에 맞춰 준다. 사용 예시는 `test/helpers/pump_test_app_test.dart`에 있다.

### Integration Test

`integration_test/`의 테스트는 실제 Chrome에서 돌고, CI에서는 아직 돌리지 않는다. 실행하려면 설치된 Chrome과 메이저 버전이 같은 chromedriver가 필요하다.

1. Chrome 버전을 확인한다(`chrome://version`).
2. [Chrome for Testing](https://googlechromelabs.github.io/chrome-for-testing/)에서 같은 메이저 버전의 chromedriver를 받는다. macOS에서 처음 실행할 때 차단되면 `xattr -d com.apple.quarantine chromedriver`로 격리 속성을 지운다.
3. 터미널 하나에서 chromedriver를 띄운다.

   ```sh
   chromedriver --port=4444
   ```

4. 다른 터미널에서 테스트를 돌린다.

   ```sh
   fvm flutter drive \
     --driver=test_driver/integration_test.dart \
     --target=integration_test/smoke_test.dart \
     -d web-server --browser-name=chrome --headless
   ```

   브라우저 창을 보면서 돌리려면 `--headless`를 `--no-headless`로 바꾼다.
