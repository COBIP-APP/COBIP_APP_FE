import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'section_flow_test_support.dart';

void main() {
  testWidgets(
    '문법: 목차 선택 → 본문 → 해당 목차 3문제 → 다음 본문 → 마지막 채점 후 완료',
    (tester) => verifySectionFlow(tester, practical: false),
  );
  testWidgets('FAILED 재제출과 PENDING 조회는 성공한 답안을 중복 제출하지 않는다', (tester) async {
    final server = SectionServer()
      ..failed = true
      ..pending = true;
    await openSectionApp(
      tester,
      server,
      '/grammar/java/chapters/31?section=311',
    );
    await tapText(tester, '다음');
    await answerSection(tester, 40);
    await reveal(tester, find.text('다음'));
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '다음'))
          .onPressed,
      isNull,
    );
    await reveal(tester, find.text('채점 서버 오류'));
    server.failed = false;
    await tapText(tester, '이 문제 다시 제출');
    server.saved[42]!.addAll({
      'gradingStatus': 'COMPLETED',
      'gradingMethod': 'AI',
      'score': 100,
      'gradedAt': server.saved[42]!['submittedAt'],
    });
    await tapText(tester, '채점 결과 새로고침');
    int posts(int id) => server.requests
        .where(
          (r) =>
              r.method == 'POST' && r.path == '/api/questions/$id/submissions',
        )
        .length;
    expect(posts(41), 1);
    expect(posts(42), 1);
    expect(posts(43), 2);
    await tapText(tester, '다음');
    expect(server.savedProgress!['lastSectionId'], 319);
    expect(tester.takeException(), isNull);
  });
  testWidgets('마지막 목차로 바로 가도 앞선 문제가 미제출이면 완료하지 않는다', (tester) async {
    final server = SectionServer();
    await openSectionApp(
      tester,
      server,
      '/grammar/java/chapters/31?section=319',
    );
    await tapText(tester, '다음');
    await answerSection(tester, 80);
    await tapText(tester, '다음');
    expect(server.savedProgress!['completedAt'], isNull);
    expect(find.textContaining('앞선 목차에 아직 채점을'), findsOneWidget);
  });
  testWidgets('문제가 없는 목차는 다음 본문으로 이동하되 본문만으로 완료하지 않는다', (tester) async {
    final server = SectionServer()..noQuestions = true;
    await openSectionApp(
      tester,
      server,
      '/grammar/java/chapters/31?section=311',
    );
    await tapText(tester, '다음');
    await tapText(tester, '다음');
    expect(find.text('설명 319'), findsOneWidget);
    await tapText(tester, '다음');
    await tapText(tester, '다음');
    expect(server.savedProgress!['completedAt'], isNull);
    expect(find.textContaining('등록된 문제가 없어 챕터를 완료할 수 없어요'), findsOneWidget);
  });
}
