# 문제 풀이와 챗봇 패널

최신 develop의 실무·마이페이지 병합 내용에서 `feature/problems-chat-panel`을 생성했습니다.

| 화면 | 파일 | 동작 |
| --- | --- | --- |
| 문제 목록 | `lib/features/problems/presentation/problems_home_screen.dart` | Java·Python·JavaScript 미션 선택, 문제 탭 표시, 프로필 이동 |
| 미션 풀이 | `lib/features/problems/presentation/problem_mission_screen.dart` | 코드 작성, 객관식 선택, 출력값 입력을 스크롤로 확인 |
| 풀이 결과 | `lib/features/problems/presentation/problem_result_screen.dart` | 정오답 표시, 선택해서 펼치는 정답·풀이, 문제 목록 복귀 |
| 공통 챗봇 패널 | `lib/features/chat/presentation/chat_panel.dart` | 현재 화면 위에 채팅 영역 표시, 입력·전송·닫기 |

## 문제 데이터와 범위

- `data/problem_sample_data.dart`에 언어별 3문항씩 총 9문항의 더미 데이터를 분리했습니다.
- 경로는 `/problems`와 `/problems/:mission`이며 잘못된 미션은 목록으로 돌아갑니다.
- 세 답안을 모두 입력한 뒤 채점하기를 누르면 결과 확인 화면을 표시합니다. 코드 입력은 공백만 입력하면 제출할 수 없습니다.
- 세 문항 모두 더미 정답으로 임시 판정합니다. 코드는 실행하지 않고 예시 코드와 문자열을 비교합니다(CRLF 정규화 및 앞뒤 공백 제거). 같은 동작의 다른 코드도 오답으로 표시될 수 있으며 이 제한을 화면에 안내합니다.
- 세 문항이 모두 정답이면 문제 목록 복귀 버튼만 표시합니다. 오답이 있으면 다시 풀기와 나가기 버튼을 제공합니다.
- 다시 풀기는 틀린 코드·객관식·출력값 문항만 답을 초기화해 보여줍니다. 이미 맞힌 답은 유지하며, 재제출 후에도 남은 오답만 반복해서 풀 수 있습니다. 정답과 풀이는 결과 카드에서 별도 버튼을 눌러야 표시됩니다.
- 완료 표시, 학습 진도, 서버 저장을 갱신하지 않습니다. 미션을 나가면 입력은 유지하지 않습니다.
- 상세·결과는 하단 메뉴를 숨기고 원형 챗봇 버튼을 제공합니다.

## 챗봇 동작

- 하단 챗봇 메뉴는 `/chat` 전용 페이지로 이동하며 챗봇 탭을 선택 표시합니다. 뒤로가기로 이전 화면에 복귀합니다.
- 학습·문제 상세의 우측 하단 원형 버튼은 기존 바텀시트 패널을 엽니다. 전용 페이지와 패널은 동일한 대화·임시 입력 데이터를 공유합니다.
- 닫기 버튼, 학습 계속하기, 바깥 영역 터치 등으로 닫아도 기존 화면의 답안과 위치를 유지합니다.
- Provider + ChangeNotifier로 앱 실행 중 대화와 입력 중인 메시지를 공유합니다. 파일·서버에 저장하지 않습니다.
- 응답은 `data/chat_sample_data.dart`의 키워드 기반 샘플입니다. AI 연결, 코드 분석, 자동 문제 맥락 전달은 없습니다.
- 패널에 더미 응답임을 표시합니다. 공백 메시지는 보낼 수 없고 입력은 1,000자로 제한합니다.
- 키보드 높이만큼 패널을 조정하며 대화 목록은 스크롤할 수 있습니다.

## 검증과 이미지

- 정적 분석 통과, 전체 테스트 20개 통과, Android debug APK 빌드 성공.

- `test/problems_chat_test.dart`: 문제 진입·답안 입력·결과 복귀, 대화/임시 입력 유지, 빈 메시지 비활성화, 작은 화면과 키보드, 잘못된 경로 검증.
- `docs/screenshots/problems-home.png`, `problem-mission.png`, `problem-result.png`, `chat-panel.png`는 한글 폰트를 적용한 위젯 렌더링 이미지입니다. 실제 Android 캡처와는 차이가 있습니다.

