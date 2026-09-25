# COBIP App FE 개발 컨벤션

Flutter 앱을 여러 팀원이 함께 개발할 때 따를 기본 규칙입니다. 현재 저장소는 기본 Flutter 시작 화면 단계이므로, 아직 결정되지 않은 상태관리·라우팅·API 패키지는 미리 고정하지 않습니다. 기능이 생기면 이 문서를 팀 합의에 따라 갱신합니다.

## 1. 브랜치와 협업

- `main`: 안정된 기준 브랜치입니다. 직접 커밋하지 않습니다.
- `develop`: 팀 통합 브랜치입니다.
- 기능 브랜치는 `develop`에서 생성하고 작업이 끝나면 PR로 `develop`에 병합합니다.
- 브랜치 이름은 소문자 영문 kebab-case로 작성합니다.

```text
feature/login-screen
fix/answer-submit-error
docs/flutter-conventions
```

- PR에는 변경 목적, 주요 변경 내용, 확인 방법을 적습니다. 화면을 바꿨다면 스크린샷을 첨부합니다.
- PR을 올리기 전에 작업 브랜치를 최신 `develop`과 맞추고, 변경 파일과 정적 분석 결과를 확인합니다.

## 2. 커밋 메시지

커밋 제목은 `type: 한국어 요약` 형식으로 간결하게 작성합니다. 한 커밋에는 한 가지 목적의 변경을 담습니다.

| 유형 | 사용 목적 | 예시 |
| --- | --- | --- |
| `feat` | 기능 추가 | `feat: 로그인 화면 추가` |
| `fix` | 오류 수정 | `fix: 답안 제출 오류 수정` |
| `docs` | 문서 변경 | `docs: 실행 방법 보완` |
| `style` | 동작 변경 없는 코드 형식 정리 | `style: 위젯 들여쓰기 정리` |
| `refactor` | 기능 변경 없는 구조 개선 | `refactor: 입력 폼 검증 분리` |
| `test` | 테스트 코드 추가·수정 | `test: 로그인 검증 테스트 추가` |
| `chore` | 설정·의존성·도구 관리 | `chore: lint 설정 정리` |

- 제목은 명령형보다 변경 내용을 짧게 표현하고, 끝에 마침표를 붙이지 않습니다.
- 필요한 경우에만 본문에 변경 이유나 주의점을 적습니다.
- 관련 없는 여러 변경을 하나의 커밋에 섞지 않습니다.

## 3. Dart 명명 규칙

Dart 공식 스타일을 따릅니다. 이름은 역할과 의미를 드러내고 `data`, `info`, `temp`처럼 맥락이 부족한 이름은 피합니다.

| 대상 | 규칙 | 예시 |
| --- | --- | --- |
| 클래스, 위젯, enum, typedef | `UpperCamelCase` | `LoginScreen`, `LearningStatus` |
| 변수, 함수, 메서드, enum 값 | `lowerCamelCase` | `userName`, `loadQuestions()` |
| 파일, 폴더, 패키지 | `lowercase_with_underscores` | `login_screen.dart`, `question_list/` |
| 라이브러리 비공개 선언 | 이름 앞에 `_` | `_validateInput()` |

- 약어도 일반 단어처럼 표기합니다: `httpClient`, `userId`.
- 변수 이름은 명사형을 우선합니다: `questionList`, `selectedAnswer`.
- 함수 이름은 동작을 드러내는 동사로 시작합니다: `loadQuestions`, `saveAnswer`, `validateEmail`.
- 불리언은 질문처럼 읽히도록 `is`, `has`, `can`, `should` 등을 붙입니다: `isLoading`, `hasError`, `canSubmit`.
- 이벤트 콜백은 `on` 또는 처리 함수는 `handle`로 목적을 드러냅니다: `onTap`, `handleSubmit`.
- 상수도 Dart 관례에 따라 `lowerCamelCase`를 사용합니다: `defaultPageSize`.
- 타입이나 접근 범위를 이름에 중복해서 표현하지 않습니다. `strUserName`, `listQuestions`처럼 타입 접두어를 붙이지 않습니다.

## 4. 파일 및 위젯 구성

- 파일 하나는 가능한 한 하나의 주요 위젯이나 책임을 다룹니다. 파일명은 주요 클래스 이름에 맞춥니다.
- 화면은 `LoginScreen`, 재사용 UI는 `PrimaryButton`처럼 역할을 이름에 나타냅니다.
- `build()` 안에 긴 비즈니스 로직을 넣지 말고, 의미 있는 작은 위젯이나 메서드로 나눕니다.
- 위젯은 화면 표시와 사용자 입력 전달에 집중합니다. API 호출·검증·복잡한 상태 처리는 별도 로직으로 옮깁니다.
- 상태가 바뀌지 않는 위젯은 가능한 `StatelessWidget`으로 만들고, 실제 로컬 상태가 필요한 경우에만 `StatefulWidget`을 사용합니다.
- `setState`는 해당 화면의 단순하고 지역적인 UI 상태에 사용합니다. 앱 전체 상태관리 패키지는 요구사항과 팀 숙련도를 확인한 후 합의합니다.
- 사용하지 않는 코드, 주석 처리한 오래된 코드, 이유가 설명되지 않은 TODO를 남기지 않습니다.

## 5. 상태관리: Provider + ChangeNotifier

화면 안에서만 쓰는 작은 상태는 `setState`를 사용하고, 여러 위젯이나 화면이 함께 읽거나 바꾸는 상태는 `provider`와 `ChangeNotifier`로 관리합니다. 예를 들어 로그인 사용자, 학습 진행 정보처럼 여러 화면에서 필요한 상태는 앱 또는 기능 범위에 Provider로 제공합니다. 모든 값을 전역 상태로 만들지는 않습니다.

### 파일과 책임

- 기능별 상태 클래스는 해당 기능의 `presentation` 폴더에 `*_view_model.dart` 파일로 둡니다. 예: `features/login/presentation/login_view_model.dart`.
- 상태 클래스는 화면에 필요한 값과 사용자 동작을 처리하고, 위젯은 그 상태를 표시합니다.
- API 호출 자체는 화면이나 ViewModel에 직접 작성하지 않습니다. API 규격이 정해진 뒤 `data`의 service/repository에 요청을 두고, ViewModel은 repository를 호출하도록 연결합니다.
- 상태 클래스는 `ChangeNotifier`를 상속합니다. 내부 상태를 직접 외부에서 바꾸지 못하게 하고, 읽기 전용 getter와 명시적인 메서드를 제공합니다.
- 값이 바뀌어 화면을 다시 그려야 할 때만 `notifyListeners()`를 호출합니다. 변경 없이 반복 호출하거나 `build()` 중 호출하지 않습니다.
- `ChangeNotifier`가 소유한 `TextEditingController`, `StreamSubscription` 같은 자원은 `dispose()`에서 정리합니다. 자원이 없다면 불필요한 정리 코드를 만들지 않습니다.

예시:

```dart
class LoginViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> signIn() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 인증 repository 연결은 API 규격이 정해진 뒤 추가합니다.
    } catch (_) {
      _errorMessage = '로그인에 실패했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### Provider 등록과 화면에서 읽기

- 필요한 상태만 그 상태를 사용하는 가장 가까운 공통 조상에 제공합니다. 정말 앱 전체에서 사용하는 의존성만 `app`의 `MultiProvider`에 등록합니다.
- Provider가 생성한 notifier의 생명주기와 `dispose()`를 관리하도록 합니다. 새 인스턴스 생성에는 `create`, 이미 만들어진 인스턴스 전달에는 `.value`를 사용하며 두 방식을 혼동하지 않습니다.
- 화면을 다시 그려야 하는 값은 `context.watch<T>()`, `Consumer<T>` 또는 필요한 값만 구독하는 `context.select<T, R>()`로 읽습니다.
- 버튼 탭 등 사용자 동작을 처리할 때는 화면 전체가 notifier 변경을 구독하지 않도록 `context.read<T>()`로 메서드를 호출합니다.
- `Consumer`/`Selector`는 변경된 상태를 실제로 표시하는 작은 위젯 주위에 둬서 불필요하게 큰 화면이 다시 빌드되지 않게 합니다.
- `build()` 안에서 매번 notifier를 생성하거나 `notifyListeners()`를 부르지 않습니다.

```dart
// 화면 표시용 구독
final isLoading = context.select<LoginViewModel, bool>(
  (viewModel) => viewModel.isLoading,
);

// 버튼 동작: 상태 변경을 구독하지 않고 메서드만 호출
onPressed: () => context.read<LoginViewModel>().signIn(),
```

### 비동기 화면 상태

- 서버 요청이 있는 화면은 최소한 로딩, 성공 데이터, 오류 상태를 구분합니다. 데이터가 없는 정상 상태가 기능에 존재한다면 빈 상태도 별도로 표시합니다.
- 버튼을 연속으로 눌러 요청이 중복되지 않도록 로딩 중 동작을 제한합니다.
- 오류를 조용히 삼키지 말고 화면에 사용자용 안내를 표시하며, 필요한 기술 정보는 민감정보를 제외해 로그로 남깁니다.
- 비동기 작업 후 `BuildContext`를 사용할 때는 `await` 이후 `context.mounted`를 확인합니다.
- notifier 하나가 여러 무관한 화면의 상태를 모두 소유하지 않도록 기능 단위로 나눕니다. 단, 실제 요구가 생기기 전에 notifier를 지나치게 잘게 쪼개지도 않습니다.

## 6. 라우팅: go_router

- 앱의 라우트 선언과 `GoRouter` 설정은 `lib/app/router/app_router.dart`에 모읍니다. 앱 전체에서 쓰는 경로 이름과 라우트 구성을 화면 파일마다 중복 선언하지 않습니다.
- 각 라우트는 명확한 경로와 화면을 연결합니다. 경로는 소문자 kebab-case로 작성합니다. 예: `/login`, `/learning/:lessonId`, `/my-page`.
- 라우트 이름을 정했다면 경로 문자열을 여기저기 직접 쓰지 않고 `goNamed`/`pushNamed`를 일관되게 사용합니다. 이름 또는 경로 중 팀에서 택한 방식을 섞어 쓰지 않습니다.
- `context.go()`는 목적지로 이동하며 현재 화면 스택을 목적지 중심으로 바꿉니다. `context.push()`는 현재 화면 위에 다음 화면을 쌓아 뒤로 돌아갈 수 있게 합니다. 목록에서 상세로 들어가는 등 뒤로 돌아올 흐름은 보통 `push`, 로그인 후 홈으로 이동하는 등 이전 화면으로 돌아가면 안 되는 흐름은 보통 `go`를 사용합니다.
- 화면에 필요한 식별자처럼 URL로 표현할 수 있는 값은 path/query parameter로 전달하고 목적지에서 검증합니다. 큰 객체나 민감정보를 `extra`에 넣어 화면 간 전달에 의존하지 않습니다. 딥링크나 앱 재시작 뒤에도 복원되어야 하는 정보는 URL 또는 저장소 등 적절한 방법을 사용합니다.
- 로그인 여부 같은 접근 제어와 리다이렉트는 라우터의 `redirect` 한 곳에서 관리합니다. 로그인 화면과 인증이 필요한 화면에서 서로 다른 중복 검사를 만들지 않습니다. 인증 저장·갱신 방식이 정해지기 전에는 리다이렉트 코드를 미리 만들지 않습니다.
- 하단 탭이 생기면 탭 전환 시 각 탭의 화면 이력과 상태를 유지해야 하는지 먼저 확인합니다. 단순 공통 레이아웃이면 `ShellRoute`, 탭별 독립적인 내비게이션 이력이 필요하면 `StatefulShellRoute.indexedStack`을 검토합니다.
- 알 수 없는 경로와 화면 생성 실패에 대해 사용자가 복귀할 수 있는 오류 화면을 지정합니다.

```dart
final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/learning/:lessonId',
      name: 'learning',
      builder: (context, state) => LearningScreen(
        lessonId: state.pathParameters['lessonId']!,
      ),
    ),
  ],
);
```

```dart
context.goNamed('home');
context.pushNamed('learning', pathParameters: {'lessonId': lessonId});
```

## 7. 폴더 구조

기능이 적을 때는 기본 Flutter 구조를 유지합니다. 화면과 기능이 늘면 기능 단위로 묶고, 실제로 여러 기능이 공유하는 코드만 공통 폴더로 이동합니다.

```text
lib/
  main.dart
  app/                 # 앱 시작, 테마, 라우팅 등 앱 전체 설정
  core/                # 여러 기능에서 공통으로 쓰는 기반 코드
  features/
    <feature_name>/    # 예: login, learning, chatbot
      presentation/    # 화면과 UI 상태 처리
      data/            # API 연결과 데이터 변환 (필요해질 때 추가)
```

- 폴더를 만들기 위해 억지로 추상화하지 않습니다. 한 기능에서만 쓰는 코드는 우선 해당 기능 안에 둡니다.
- API 서비스, 저장소, 모델을 추가할 때는 각 책임을 구분합니다. 데이터베이스나 API 규격이 확정되기 전에는 임의의 모델·계층을 먼저 만들지 않습니다.

## 8. 코드 형식과 분석

- 저장 전 `dart format .`을 실행합니다.
- 변경을 PR로 올리기 전 `flutter analyze`를 실행하고 새 오류·경고를 해결합니다.
- `analysis_options.yaml`의 `flutter_lints` 규칙을 기본으로 따릅니다. 예외 주석을 추가할 때는 필요한 줄에만 적용하고 이유를 남깁니다.
- import는 `dart:` 라이브러리, `package:` 라이브러리, 상대 경로 순서로 정리하고 그룹 사이에 빈 줄을 둡니다.
- `dynamic`은 불가피한 경우에만 사용하고, 외부 데이터는 가능한 명시적인 타입으로 변환해 사용합니다.
- 비동기 작업에는 로딩·성공·실패 상태를 고려합니다. `BuildContext`를 비동기 대기 이후 사용할 때는 위젯이 여전히 마운트되어 있는지 확인합니다.

## 9. 화면 문구, 이벤트, 다국어

- 버튼 탭, 입력 변경, 화면 이동, API 요청은 기능 구현 시 상태 변화와 오류 처리를 명확히 연결합니다. 여기서 말하는 이벤트 처리는 사용자 동작에 대한 앱의 반응입니다.
- 사용자 행동 분석을 위한 별도 이벤트 수집은 제품에서 수집할 항목과 동의·개인정보 방침이 정해진 뒤 추가합니다. 초기 기본 세팅에는 분석 SDK를 넣지 않습니다.
- 화면 문구를 코드 곳곳에 흩어 놓지 않도록 합니다. 지원 언어와 번역 운영 방식이 결정되면 Flutter `gen_l10n`과 ARB 파일 적용 여부를 팀에서 정합니다.

## 10. 의존성, 설정, 보안

- 패키지를 추가하기 전에 필요한 이유와 유지관리 상태를 확인하고 팀에 공유합니다. 버전 범위는 기존 `pubspec.yaml` 정책을 따릅니다.
- 앱 저장소에서는 `pubspec.lock`을 커밋해 팀원 간 의존성 해석을 맞춥니다.
- API 주소는 개발·운영 환경에 맞게 분리하며 코드에 로컬 주소를 고정하지 않습니다.
- 비밀번호, 토큰, 키, 개인별 설정은 저장소에 올리지 않습니다. 비밀값이 필요하면 안전한 환경 설정 전달 방식을 팀에서 합의합니다.

## 11. 커밋하지 않는 파일

- `android/local.properties` 등 개인 PC의 SDK 경로가 포함된 설정
- `.dart_tool/`, `build/` 등 생성 캐시와 빌드 산출물
- IDE 개인 설정, 임시 파일, 로그
- 비밀번호·토큰·키 등 비밀값을 포함한 파일

커밋 대상이 의심되면 `git status`와 `.gitignore`를 확인하고, 이미 추적 중인 파일은 단순히 `.gitignore`에 추가하는 것만으로 제외되지 않는다는 점을 유의합니다.

## 참고 기준

- [Effective Dart: Style](https://dart.dev/effective-dart/style)
- [Flutter app architecture recommendations](https://docs.flutter.dev/app-architecture/recommendations)
- [Flutter: Simple app state management](https://docs.flutter.dev/data-and-backend/state-mgmt/simple)
- [go_router package](https://pub.dev/packages/go_router)
