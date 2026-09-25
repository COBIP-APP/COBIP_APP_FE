# COBIP App FE

COBIP Android 앱의 Flutter 프로젝트입니다. 현재는 Flutter 기본 시작 화면만 포함하며, COBIP 기능과 서버 연동은 아직 추가하지 않았습니다.

## 개발 환경

- Flutter stable 3.47.5
- Dart 3.13.4
- Android SDK 36

팀원은 Flutter SDK와 Android Studio의 Flutter/Dart 플러그인을 설치한 뒤 프로젝트를 실행합니다.

## 실행

프로젝트 루트에서 실행합니다.

```powershell
flutter pub get
flutter run
```

실행할 Android 기기나 에뮬레이터가 여러 개라면 `flutter devices`로 기기를 확인하고 `flutter run -d <device-id>`를 사용합니다.

## 팀 규칙

브랜치, 커밋, Dart 스타일과 폴더 구조는 [CONVENTIONS.md](CONVENTIONS.md)를 따릅니다.
