# 마이페이지 실제 API 연동

구현·검증일: 2026-10-12. 브랜치: `feature/my-page`.

기존 더미 화면은 디자인 참고로만 사용하고, 현재 BE에서 구현한 API에 맞춰 화면을 구성했다. 신규 BE 엔드포인트나 DB 변경은 없다.

계정 관리는 프로필 카드 오른쪽 위 톱니바퀴에서 별도 `/my-page/account-settings` 페이지로 이동한다. 하단 탭은 내 학습·북마크·최근 결과만 제공한다. 계정 페이지는 프로필을 직접 조회하며 뒤로 가기, 비밀번호 재설정, 로그아웃을 제공한다.

내 학습에는 전체 보기·학습 중·학습 완료 필터를 제공하며 기본값은 전체 보기다. 유저 카드·학습 요약·기록 카드에는 공통 그림자를 적용했다.

## 화면과 API

| 화면 | API와 동작 |
| --- | --- |
| 프로필·계정 관리 | `GET /api/users/me`: 닉네임, 이메일, 역할, 가입일 |
| 내 학습 | `GET /api/users/me/progress`: 학습 중/완료, 제목, 분류·언어, 마지막 목차, 최근 학습일·완료일 |
| 이어서 학습·다시 보기 | 템플릿 상세와 분류·언어 API로 실제 라우팅 정보를 확인하고 기존 학습 화면으로 이동 |
| 북마크 | `GET /api/users/{userId}/bookmarks`: 제목, 요약, 난이도, 저장일 |
| 북마크 해제 | 기존 DELETE API 성공 후 목록에서 제거하고 공용 학습 저장소 갱신 |
| 최근 결과 | 공개 문제 목록과 각 문제의 latest 제출 조회를 조합. 탭을 처음 열 때 조회하고 최대 4개 요청씩 실행 |
| 비밀번호 재설정·로그아웃 | 기존 인증 화면과 `AuthViewModel` 재사용 |

학습 중·완료·북마크 개수는 성공한 API 응답으로 계산한다. 조회 실패를 0개나 더미 성공으로 바꾸지 않는다. 영역별 로딩·빈 목록·오류·재시도와 새로고침을 제공한다. 계정별 ViewModel을 분리하고 화면 종료 시 요청을 취소해 이전 응답이 다른 계정에 표시되지 않게 한다.

최근 결과는 **현재 공개된 문제별 최신 BE 제출**만 포함한다. 전체 제출 이력이나 누적 성적 통계가 아니다. 서버에 저장되지 않은 AI 연습 결과는 포함하지 않는다. `PENDING`은 채점 대기, `FAILED`는 채점 오류로 표시하고 점수는 완료된 결과에만 표시한다. 최신 제출의 404만 미제출로 처리하며 서버 오류를 빈 결과로 바꾸지 않는다.

## 구현 위치

- `lib/features/my_page/data/my_page_api.dart`: 표시용 응답 모델, 인증된 Dio 조회, 최신 제출 조합, 학습 경로 결정.
- `lib/features/my_page/presentation/my_page_view_model.dart`: 영역별 상태, 중복 요청 방지, 취소·수명 관리, 북마크 해제.
- `lib/features/my_page/presentation/my_page_screen.dart`: API 기반 화면과 기존 라우트 연결.
- `lib/features/learning/presentation/learning_store.dart`: 다른 화면의 북마크 변경 이후 진행 중인 조회가 끝나면 다시 갱신.

## 검증 결과

- PR 최종 전체 Flutter 테스트 **224개 통과**. 마이페이지 신규 테스트 11개와 홈 상세 이동 검증 포함.
- `flutter analyze`: 문제 없음.
- `dart format --output=none --set-exit-if-changed lib test`: 변경 없음.
- `flutter build apk --debug --no-pub --dart-define=API_BASE_URL=http://10.0.2.2:8080`: 성공.
- 새 에뮬레이터 `COBIP_MyPage_Clean_20261012`에 APK 설치. 로컬 BE의 실제 테스트 계정으로 프로필, 학습 중 1개·완료 1개, 최근 객관식 결과 100점 표시 확인.
- 내 학습의 이어하기에서 저장된 `else와 else if 사용하기` 목차(2/3)로 이동 확인.
- 학습 화면에서 북마크 추가 → 마이페이지 복귀 후 1개 반영 → 마이페이지에서 해제 → 0개와 빈 목록 표시 확인. 검증용 북마크는 원래 상태로 복구했다.
- APK 재설치·앱 재시작 후 기존 로그인 복원 확인. DB 초기화는 수행하지 않았다.
- 전체 보기·학습 중·학습 완료 필터를 실제 학습 중/완료 기록으로 전환 확인했다.

최종 화면: [마이페이지](screenshots/mypage-api.png), [계정 관리](screenshots/mypage-account-settings.png), [AI 실무 문제 생성](screenshots/ai-practical-generation.png).

모의 HTTP 기반 테스트는 오류 격리·재시도, 북마크 삭제 실패, nullable 필드, 제출 404/500 구분, 채점 대기, 늦은 응답 무시, 서버 ID 기반 이동, 공용 저장소 갱신 경쟁, 로그아웃, 좁은 화면·큰 글씨를 검증한다. 실제 SMTP 비밀번호 재설정 완료와 실서버 토큰 만료·계정 전환은 이번 에뮬레이터 검증에 포함하지 않았다.
