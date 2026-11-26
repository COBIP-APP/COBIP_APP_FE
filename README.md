# COBIA Android 앱

COBIA는 프로그래밍 입문자가 문법에서 실무 주제까지 이어서 학습할 수 있도록 만든 Android 앱입니다. 챕터별 설명과 예제 코드를 읽고 문제를 풀며, 학습 위치와 풀이 결과를 확인할 수 있습니다. AI 문제 생성과 챗봇도 제공합니다.

이 저장소는 **Flutter 앱**입니다. 계정·학습 콘텐츠·진도는 [COBIP_APP_BE](https://github.com/COBIP-APP/COBIP_APP_BE) API가 처리하고, AI 문제 생성·챗봇은 별도 AI 서비스에 요청합니다. 기존 COBIP 웹과 COBIA 앱은 별도의 백엔드와 DB를 사용합니다.

## 주요 기능

| 화면 | 할 수 있는 일 |
| --- | --- |
| 계정 | 이메일 인증 후 회원가입, 로그인, 비밀번호 재설정 |
| 홈·문법·실무 | 언어와 주제별 챕터 선택, 목차·Markdown 본문·예제 코드 확인 |
| 문제 | 공개 문제 풀이, AI 문제 생성·채점, 생성 문제 저장 |
| 챗봇 | 개발·학습 관련 질문과 AI 답변 확인 |
| 마이페이지 | 학습 진도, 북마크, 저장한 문제와 최근 결과 확인 |

콘텐츠는 [관리자 웹](https://github.com/COBIP-APP/COBIP_APP_ADMIN)에서 등록·공개합니다. 새 DB에서 학습 목록이 비어 있다면 먼저 콘텐츠를 등록해야 합니다.

## 실행 준비

- Flutter SDK와 Android Studio·Android SDK
- 실행 중인 Android 에뮬레이터 또는 Android 기기
- 로그인·학습용 백엔드 서버. 로컬에서 실행하려면 [백엔드 README](https://github.com/COBIP-APP/COBIP_APP_BE)를 먼저 따릅니다.

이 프로젝트의 `pubspec.yaml`은 Dart SDK `^3.13.4`를 요구합니다. 아래 명령은 **Windows PowerShell** 기준입니다.

```powershell
git clone --branch develop https://github.com/COBIP-APP/COBIP_APP_FE.git
cd COBIP_APP_FE
flutter pub get
flutter devices
```

### 로컬 백엔드와 연결해 실행

같은 PC에서 백엔드 Docker Compose를 실행했다면 Android 에뮬레이터에서는 다음 명령을 사용합니다. `emulator-5554`가 다르면 `flutter devices`에 나온 기기 ID로 바꿉니다.

```powershell
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

이 명령에서는 계정·학습 API만 로컬 백엔드에 연결됩니다. AI 주소는 기본값인 `https://ai.cobip.tech`를 사용합니다. **AI까지 로컬에서 실행한 경우에만** 다음처럼 두 주소를 함께 지정합니다.

```powershell
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8080 --dart-define=AI_BASE_URL=http://10.0.2.2:8000
```

`10.0.2.2`는 Android 에뮬레이터에서 같은 PC를 가리키는 주소입니다. 실제 휴대전화에서 로컬 서버에 접속할 때는 PC의 LAN 주소와 서버·방화벽 설정이 별도로 필요합니다. 위 HTTP 주소는 개발 실행용입니다.

### 운영 서버와 연결해 실행

별도 주소를 지정하지 않으면 앱은 `https://api.cobia.shop`과 `https://ai.cobip.tech`를 사용합니다. 두 서버가 켜져 있고 인터넷에 연결되어 있어야 합니다.

```powershell
flutter run -d emulator-5554
```

## 앱 사용 순서

1. **회원가입:** 이메일 입력 → 인증 요청 → 메일로 받은 코드 확인 → 닉네임·비밀번호 입력. 메일 발송에는 백엔드 SMTP 설정이 필요합니다.
2. **학습:** 홈에서 문법 또는 실무를 선택 → 챕터 소개와 목차 확인 → 본문·예제 읽기 → 연결된 문제 풀이.
3. **문제·AI:** 공개 문제를 풀거나 AI 문제를 생성합니다. 생성한 문제를 저장하면 다시 찾아볼 수 있습니다.
4. **기록:** 마이페이지에서 학습 위치, 북마크, 저장한 문제와 최근 결과를 확인합니다.

AI 답변과 채점은 학습을 돕는 참고 정보입니다. 중요한 코드·사실은 직접 확인하세요.

## 서버 주소와 빌드

| 빌드 변수 | 기본값 | 역할 |
| --- | --- | --- |
| `API_BASE_URL` | `https://api.cobia.shop` | 인증·콘텐츠·진도·저장된 문제 API |
| `AI_BASE_URL` | `https://ai.cobip.tech` | AI 문제 생성·채점·챗봇 API |

AI 요청은 기본적으로 AI 서버에 직접 보냅니다. 일반 API와 AI API는 서로 다른 주소를 사용하므로 로컬 실행 시 각각의 연결 상태를 확인하세요. 릴리스 빌드에는 HTTPS 주소를 사용합니다.

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://api.cobia.shop --dart-define=AI_BASE_URL=https://ai.cobip.tech
```

결과 APK: `build/app/outputs/flutter-apk/app-release.apk`. APK에 지정한 서버 주소는 빌드할 때 정해지므로 주소를 바꾸려면 다시 빌드해야 합니다.

## 문제가 생기면

- **서버에 연결할 수 없음:** 백엔드가 실행 중인지 확인하고, `API_BASE_URL`이 현재 실행 방식과 맞는지 확인합니다.
- **인증 메일이 오지 않음:** 스팸함과 백엔드 SMTP 설정을 확인합니다.
- **학습 목록이 비어 있음:** 백엔드 DB에 관리자가 공개한 챕터·문제가 있는지 확인합니다.
- **AI만 동작하지 않음:** `AI_BASE_URL`의 AI 서버 상태를 확인합니다. 백엔드가 정상이어도 AI 서버는 별도로 중단될 수 있습니다.

프로젝트 내부 구성과 개발 규칙은 [CONVENTIONS.md](CONVENTIONS.md), API 연동 기록은 [docs](docs)를 참고하세요.
