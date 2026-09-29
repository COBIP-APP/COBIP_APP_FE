# 실무 학습 화면

문법 화면에서 이어지는 `feature/practical-learning-screens` 브랜치에서 작업합니다.
스토리보드의 한 페이지 목차/앵커 구조를 사용자 요청에 따라 주제 → 챕터 목록 → 챕터 상세 구조로 변경했습니다.

| 페이지 | 파일 | 역할 |
| --- | --- | --- |
| 실무 주제 | `lib/features/practical/presentation/practical_home_screen.dart` | 검색, 카테고리 필터, 카드 전체 터치로 챕터 목록 이동 |
| 챕터 목록 | `lib/features/practical/presentation/practical_chapters_screen.dart` | 주제별 챕터 선택 |
| 챕터 상세 | `lib/features/practical/presentation/practical_chapter_screen.dart` | 핵심 개념, 예제, 이전/다음 챕터, 목록 복귀 |

## 데이터와 표시

- `lib/features/practical/data/practical_sample_data.dart`에 캐시 4개, DB·네트워크·로그 각각 3개로 총 13개 챕터를 정의했습니다.
- 모두 로컬 더미 콘텐츠입니다. 코드 실행, 서버/API 호출, 학습 완료·진도 저장은 없습니다.
- 상세의 챕터 번호는 현재 읽는 위치이며 학습 성취도가 아닙니다.
- 실무 주제 및 챕터 목록에서는 상단/하단 바를 유지하고 실무 탭을 선택 표시합니다.
- 상세는 하단 바를 숨기고 작은 원형 챗봇 버튼을 표시합니다. 챗봇은 준비 중 안내만 제공합니다.
- 즐겨찾기, 페이지 나누기, 실무 퀴즈는 이번 범위에 포함하지 않습니다.

## 경로와 이동

- `/practical`: 실무 주제 목록
- `/practical/:topic/chapters`: 주제별 챕터 목록
- `/practical/:topic/chapters/:chapter`: 챕터 상세
- 이전/다음은 상세 화면을 교체하므로 뒤로가기에 방문한 모든 챕터가 쌓이지 않습니다.
- 잘못된 주제는 실무 목록, 잘못된 챕터는 해당 주제의 챕터 목록으로 이동합니다.
- 하단 홈 버튼은 방문 순서와 관계없이 홈으로 이동합니다.

## 확인

`test/practical_learning_test.dart`에서 검색/필터, 탭 이동, 챕터 탐색, 목록 복귀, 잘못된 주소, 전체 챕터의 좁은 화면과 큰 글씨 배치를 확인합니다.
실제 Android 기기에서 글꼴과 스크롤 느낌은 별도 확인할 수 있습니다.

검증 결과: Flutter 정적 분석 통과, 기존 테스트 13개 통과 및 실무 테스트 3개 재검증 통과, Android debug APK 빌드 성공.
`docs/screenshots/practical-home.png`, `practical-chapters.png`, `practical-chapter.png`는 위젯 렌더링 이미지입니다. Android 기기 캡처는 아니며 로컬 한글 폰트를 사용했습니다.

주제 카드의 태그는 표시용이며 검색 동작은 없습니다. 목록 상단은 문법과 같은 COBIP·프로필 형태입니다.
