import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cobip_app_fe/features/grammar/presentation/grammar_chapters_screen.dart';

import 'section_flow_test_support.dart';

class _GrammarOutlineServer extends SectionServer {
  @override
  Map<String, dynamic> get template => super.template
    ..['sections'] = [
      {
        'id': 900,
        'parentId': null,
        'title': '1. 개요',
        'body': '파이썬 기초 개요',
        'media': [],
        'children': [
          for (final section in sections) {...section, 'parentId': 900},
        ],
      },
    ];
}

void main() {
  testWidgets('문법 개요의 다음은 빈 문제 화면 없이 첫 하위 본문으로 이동한다', (tester) async {
    final server = _GrammarOutlineServer();
    await openSectionApp(
      tester,
      server,
      '/grammar/java/chapters/31?section=900',
    );
    await tapText(tester, '다음');
    expect(find.text('설명 311'), findsOneWidget);
    expect(find.text('이 목차에 연결된 문제는 아직 없어요.'), findsNothing);
    expect(server.savedProgress!['lastSectionId'], 311);
    expect(server.savedProgress!['completedAt'], isNull);
    await tapText(tester, '다음');
    expect(find.text('목차 311 · 문제'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
      isNotNull,
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
    expect(find.byType(GrammarChaptersScreen), findsOneWidget);
  });
  testWidgets('문제가 없는 목차는 다음 본문으로 이동하되 본문만으로 완료하지 않는다', (tester) async {
    final server = SectionServer()..noQuestions = true;
    await openSectionApp(
      tester,
      server,
      '/grammar/java/chapters/31?section=311',
    );
    await tapText(tester, '다음');
    expect(find.text('설명 319'), findsOneWidget);
    await tapText(tester, '다음');
    expect(server.savedProgress!['completedAt'], isNull);
    expect(find.byType(GrammarChaptersScreen), findsOneWidget);
  });
}
