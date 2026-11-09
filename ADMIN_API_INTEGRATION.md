# 관리자 API 연동 안내

## 적용 범위

- 관리자 Google 로그인, 현재 관리자 조회, 로그아웃을 백엔드 API에 연결했습니다.
- 관리자 공간 목록, 상세, 신규 등록, 섹션별 수정, 공개 상태 변경, 재조사 요청 일괄 처리 및 선택적 비공개 전환을 백엔드 API에 연결했습니다.
- 건물 목록은 `GET /api/admin/buildings`에서 조회합니다.
- 사진은 `POST /api/admin/photos`로 한 장씩 업로드하고 응답의 사진 ID를 공간 등록/수정 요청에 전달합니다.
- 화면 UI는 유지하고 Repository 구현을 Mock에서 API 기반으로 교체했습니다.

## 로컬 실행

1. 백엔드 실행 환경을 준비합니다. 백엔드 저장소 안내 기준 JDK 21과 Docker가 필요합니다.
2. 백엔드 서버가 `http://localhost:8080`에서 실행되도록 합니다.
3. 백엔드의 로컬 실행 설정에서 다음 값이 프론트엔드와 일치하는지 확인합니다.
   - Google OAuth Client ID: `273043781488-i77ccsr0tqi878plo8sa2at2o7l5c0cf.apps.googleusercontent.com`
   - 관리자 허용 목록: 실제 로그인할 Google 계정 이메일
   - 세션 서명 키: 로컬 전용의 충분히 긴 임의 문자열
4. 프론트엔드 폴더에서 실행합니다.

```bash
fvm flutter pub get
fvm flutter run -d chrome
```

개발 서버는 `web_dev_config.yaml` 설정에 따라 브라우저의 `http://localhost:3000`에서 `/api/` 요청을 `http://localhost:8080/`으로 전달합니다. `ApiClient`는 빈 `baseUrl`과 상대 경로를 유지해야 세션 쿠키가 같은 오리진 요청에 포함됩니다.

## 백엔드 로컬 설정 주의

현재 전달된 백엔드 ZIP의 `build.gradle.kts`에는 `bootRun`/`bootTestRun`용으로 `local-google-client-id`와 `local-admin@example.com`이 기본 인자로 지정되어 있습니다. 이 값은 위 프론트엔드 OAuth Client ID 및 실제 관리자 계정과 다르므로, 기본값 그대로 서버를 실행하면 Google 인증이 실패하거나 403이 발생할 수 있습니다. 백엔드 실행 설정을 실제 개발용 Client ID와 허용 관리자 이메일에 맞춰야 합니다.

사진 업로드에는 백엔드의 S3 접근 자격 증명과 실제 버킷 설정도 필요합니다. 백엔드의 `.env.example`은 예시 파일이므로 실제 `.env`/AWS 권한이 별도로 준비되어 있는지 확인하세요.

## 검증 순서

1. Google 로그인 성공 여부 확인
2. `GET /api/admin/me` 성공 및 세션 쿠키 유지 확인
3. 관리자 공간 목록 및 건물 목록 조회 확인
4. 테스트 DB에서 사진 업로드와 공간 등록 확인
5. 상세 조회, 각 섹션 수정, 공개 상태 변경 및 재조사 처리 확인

운영 API를 대상으로 등록·수정 테스트를 하지 마세요. 운영 환경 확인은 조회만 수행하고, 쓰기 기능은 별도 테스트 DB에서 검증해야 합니다.
