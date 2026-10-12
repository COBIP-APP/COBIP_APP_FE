# COBIP App FE

COBIP Android 앱의 Flutter 프로젝트입니다. 인증·회원가입·비밀번호 재설정과 메인의 공개 학습·진도 조회는 백엔드 API를 사용합니다. 문법·실무·문제 등 다른 팀원의 학습 상세 화면은 기존 구현을 유지합니다.

## 개발 환경

- Flutter stable 3.47.5
- Dart 3.13.4
- Android SDK 36

팀원은 Flutter SDK와 Android Studio의 Flutter/Dart 플러그인을 설치한 뒤 프로젝트를 실행합니다.

## 실행

프로젝트 루트에서 실행합니다.

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

실행할 Android 기기나 에뮬레이터가 여러 개라면 `flutter devices`로 기기를 확인하고 `flutter run -d <device-id>`를 사용합니다.

`API_BASE_URL`은 백엔드 호스트 주소입니다. 위 주소는 같은 PC에서 실행한 개발 서버에 Android 에뮬레이터로 연결하는 예시이며 서버를 자동으로 실행하지 않습니다. 실기기는 접근 가능한 개발 서버 주소를 별도로 사용합니다. 릴리스에서는 HTTPS 주소가 필요합니다. 주소 미설정·서버 오류를 모의 성공으로 처리하지 않습니다.

AI 문제 생성·채점·챗봇·추가 해설은 현재 운영 AI 서버를 직접 호출합니다. `AI_BASE_URL`의 기본값은 팀에서 전달한 `https://ai.cobip.tech`이며 별도 Dio를 사용해 BE 로그인 토큰을 AI 서버에 보내지 않습니다. 로그인·학습 조회·기존 답안 저장은 계속 `API_BASE_URL`을 사용합니다. AI 요청의 응답 제한 시간은 5분이며 자동 재전송하지 않습니다.

다른 AI 서버를 사용할 때는 `--dart-define=AI_BASE_URL=https://...`을 지정합니다. 추후 Spring이 동일한 `/ai/...` 요청·응답을 중계하면 `--dart-define=AI_USE_BE_PROXY=true`로 빌드하여 기존 BE 주소와 인증을 사용할 수 있습니다. 현재 기본값은 직접 호출이며, 직접 호출 실패 시 BE로 자동 우회하지 않습니다. 팀의 최종 `/api/ai/chat`·관리자 생성 경로는 별도 계약이므로 이 옵션만으로 전환되지 않습니다.

생성 문제의 `문제 저장`, 작성자 표시, `내가 만든 문제` 필터는 FE에 추가했습니다. 일반 사용자용 `POST/GET /api/users/me/questions`는 **BE 신규 구현이 필요한 제안 계약**입니다. API가 없으면 저장/조회 준비 안내를 표시하며 성공으로 처리하지 않습니다. 요청·응답 JSON, 작성자 권한, 중복 저장 방지, 추가 문제 유형과 기존 제출 API 확장 내용은 [BE 구현 요청](docs/learning-api-preview.md#2026-10-12-생성-문제-저장작성자내-문제-필터-be-구현-요청)에 정리했습니다.

메일 인증에는 승인된 개발 서버의 SMTP 설정과 테스트 메일함이 필요합니다. SMTP 비밀번호·JWT 비밀값은 앱에 넣지 않습니다. 회원가입 성공 후에는 로그인 화면에서 별도로 로그인합니다.

프로젝트 내부 SDK를 사용하는 경우 `.tools/flutter/bin/flutter.bat`와 `.tools/flutter/bin/dart.bat`를 사용하고 `PUB_CACHE`, `APPDATA`, `GRADLE_USER_HOME`은 기존 `.tools` 설정을 유지합니다. SDK·캐시가 루트 안에 있으면 소스 포맷 검사는 `dart format --output=none --set-exit-if-changed lib test`로 범위를 제한할 수 있습니다.

인증 계약, 변경 범위와 실제 서버 검증 보류 항목은 [인증 연동 작업 기록](docs/auth-api-integration.md)을 참고합니다.

메인의 조회 API, 빈 상태·오류 처리와 학습 상세 이동의 남은 경계는 [메인 API 연동 작업 기록](docs/home-api-integration.md)을 참고합니다.

프로필·내 학습·북마크·문제별 최근 결과와 계정 기능은 [마이페이지 API 연동 작업 기록](docs/mypage-api-integration.md)을 참고합니다.

## 팀 규칙

브랜치, 커밋, Dart 스타일과 폴더 구조는 [CONVENTIONS.md](CONVENTIONS.md)를 따릅니다.
