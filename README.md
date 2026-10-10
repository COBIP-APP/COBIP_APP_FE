# COBIP App FE

COBIP Android 앱의 Flutter 프로젝트입니다. 인증·회원가입·비밀번호 재설정은 백엔드 API를 사용하며, 학습 화면의 샘플 데이터는 기존 팀 구현을 유지합니다.

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

메일 인증에는 승인된 개발 서버의 SMTP 설정과 테스트 메일함이 필요합니다. SMTP 비밀번호·JWT 비밀값은 앱에 넣지 않습니다. 회원가입 성공 후에는 로그인 화면에서 별도로 로그인합니다.

프로젝트 내부 SDK를 사용하는 경우 `.tools/flutter/bin/flutter.bat`와 `.tools/flutter/bin/dart.bat`를 사용하고 `PUB_CACHE`, `APPDATA`, `GRADLE_USER_HOME`은 기존 `.tools` 설정을 유지합니다. SDK·캐시가 루트 안에 있으면 소스 포맷 검사는 `dart format --output=none --set-exit-if-changed lib test`로 범위를 제한할 수 있습니다.

인증 계약, 변경 범위와 실제 서버 검증 보류 항목은 [인증 연동 작업 기록](docs/auth-api-integration.md)을 참고합니다.

## 팀 규칙

브랜치, 커밋, Dart 스타일과 폴더 구조는 [CONVENTIONS.md](CONVENTIONS.md)를 따릅니다.
