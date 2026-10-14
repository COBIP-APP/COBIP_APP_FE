import 'dart:async';

import 'package:cobip_app_fe/features/learning/presentation/template_preview_screen.dart';
import 'package:cobip_app_fe/features/practical/presentation/practical_home_screen.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_practice_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'auth_test_support.dart';
import 'learning_test_support.dart';
import 'section_flow_test_support.dart';

class _PracticalServer extends SectionServer {
  _PracticalServer({this.withEmptySections = false}) : super(practical: true);
  final bool withEmptySections;

  Map<String, dynamic> emptySection(int id, int? parentId) => {
    'id': id,
    'parentId': parentId,
    'title': '빈 목차 $id',
    'body': '문제가 없는 본문 $id',
    'exampleCode': null,
    'media': [],
    'children': [],
  };

  @override
  List<Map<String, dynamic>> get sections => [
    super.sections.first,
    if (withEmptySections) emptySection(997, 300),
    super.sections.last,
  ];

  @override
  Map<String, dynamic> get template {
    final item = super.template;
    if (withEmptySections) {
      (item['sections'] as List).add({
        ...emptySection(700, null),
        'children': [emptySection(123, 700)],
      });
    }
    return item;
  }
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> enterAnswer(WidgetTester tester, int id, String answer) async {
  final field = find.byKey(ValueKey('answer-$id'));
  await reveal(tester, field);
  await tester.enterText(field, answer);
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
}

int submissions(SectionServer server, int id) => server.requests
    .where(
      (r) => r.method == 'POST' && r.path == '/api/questions/$id/submissions',
    )
    .length;

void main() {
  for (final practical in [false, true]) {
    testWidgets('${practical ? '실무' : '문법'}에서 채점 후 개별 다시 풀기와 재제출을 제공한다', (
      tester,
    ) async {
      final server = SectionServer(practical: practical);
      final store = await openSectionApp(
        tester,
        server,
        '/${practical ? 'learning' : 'grammar'}-practice/31?section=311',
      );
      await enterAnswer(tester, 42, '기존 코드 답안');
      await enterAnswer(tester, 43, '다른 문제의 미제출 답안');
      await tapKey(tester, 'choice-41-A');
      await tapKey(tester, 'submit-41');
      final firstChoiceResult = store.latest(41)!;
      expect(firstChoiceResult.score, 0);
      expect(find.text('다시 풀기'), findsOneWidget);
      expect(find.text('확인 완료'), findsNothing);
      await tapKey(tester, 'explanation-toggle-41');
      expect(find.text('서버 해설'), findsOneWidget);

      await tapKey(tester, 'submit-41');
      expect(submissions(server, 41), 1);
      expect(store.latest(41), same(firstChoiceResult));
      expect(store.practiceDraft(41), '');
      expect(find.byKey(const ValueKey('result-41')), findsNothing);
      expect(find.text('서버 해설'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('submit-41')))
            .onPressed,
        isNull,
      );
      await tapKey(tester, 'practice-previous');
      await tapText(tester, '다음');
      expect(find.byKey(const ValueKey('result-41')), findsNothing);
      await tapKey(tester, 'choice-41-B');
      await tapKey(tester, 'submit-41');
      expect(submissions(server, 41), 2);
      expect(store.latest(41)!.id, isNot(firstChoiceResult.id));
      expect(store.latest(41)!.selectedChoiceKey, 'B');
      expect(store.practiceDraft(41), isNull);
      expect(find.text('서버 해설'), findsNothing);

      await tapKey(tester, 'submit-42');
      final firstCodeResult = store.latest(42)!;
      expect(firstCodeResult.score, 100);
      await tapKey(tester, 'submit-42');
      await reveal(tester, find.byKey(const ValueKey('answer-42')));
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('answer-42')),
      );
      expect(field.enabled, isTrue);
      expect(field.controller!.text, '');
      expect(store.latest(42), same(firstCodeResult));
      expect(submissions(server, 42), 1);
      await enterAnswer(tester, 42, '다시 작성한 코드');
      server.handle = (request) async {
        if (request.method == 'POST' &&
            request.path == '/api/questions/42/submissions') {
          return jsonResponse({}, 500);
        }
        return server.respond(request);
      };
      await tapKey(tester, 'submit-42');
      expect(find.textContaining('입력한 답안은 유지됩니다'), findsOneWidget);
      expect(store.latest(42), same(firstCodeResult));
      expect(store.practiceResult(42), isNull);
      expect(store.practiceDraft(42), '다시 작성한 코드');
      server.handle = server.respond;
      await tapKey(tester, 'submit-42');
      expect(submissions(server, 42), 3);
      expect(store.latest(42)!.sourceCode, '다시 작성한 코드');
      expect(store.practiceResult(42), same(store.latest(42)));
      expect(store.practiceDraft(43), '다른 문제의 미제출 답안');
      expect(submissions(server, 43), 0);
      expect(store.latest(41)!.selectedChoiceKey, 'B');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('한 문제만 채점하고 다른 입력을 유지하며 이전·홈·목차와 다음을 제공한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final server = _PracticalServer();
    final store = await openSectionApp(
      tester,
      server,
      '/practical/204/templates/31?section=311',
    );
    await tapText(tester, '다음');
    for (final id in [41, 42, 43]) {
      final button = find.byKey(ValueKey('submit-$id'));
      await reveal(tester, button);
      expect(
        find.descendant(of: button, matching: find.text('답 확인')),
        findsOneWidget,
      );
    }
    expect(find.byTooltip('목차'), findsOneWidget);
    expect(find.text('학습으로 돌아가기'), findsNothing);
    expect(find.text('목차로 돌아가기'), findsNothing);
    await enterAnswer(tester, 42, 'int score = 65;');
    await enterAnswer(tester, 43, '아직 제출하지 않은 설명');
    await tapKey(tester, 'choice-41-B');
    await tapKey(tester, 'submit-41');
    expect(submissions(server, 41), 1);
    expect(submissions(server, 42), 0);
    expect(submissions(server, 43), 0);
    expect(store.latest(41)!.score, 0);
    expect(find.text('서버 해설'), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('submit-41'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('result-41'))).dy),
    );
    await tapKey(tester, 'explanation-toggle-41');
    expect(find.text('서버 해설'), findsOneWidget);
    await tapKey(tester, 'explanation-toggle-41');
    expect(find.text('서버 해설'), findsNothing);
    await reveal(tester, find.byKey(const ValueKey('answer-42')));
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('answer-42')))
          .controller!
          .text,
      'int score = 65;',
    );
    await reveal(tester, find.byKey(const ValueKey('answer-43')));
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('answer-43')))
          .controller!
          .text,
      '아직 제출하지 않은 설명',
    );
    await reveal(tester, find.byKey(const ValueKey('practice-next')));
    final buttons = [
      'practice-previous',
      'practice-home',
      'practice-next',
    ].map((key) => find.byKey(ValueKey(key))).toList();
    expect(tester.getCenter(buttons[0]).dy, tester.getCenter(buttons[1]).dy);
    expect(tester.getCenter(buttons[1]).dy, tester.getCenter(buttons[2]).dy);
    await tapKey(tester, 'practice-previous');
    expect(find.text('설명 311'), findsOneWidget);
    await tapText(tester, '다음');
    await reveal(tester, find.byKey(const ValueKey('result-41')));
    expect(find.text('서버 해설'), findsNothing);
    expect(find.text('풀이 보기'), findsOneWidget);
    await reveal(tester, find.byKey(const ValueKey('answer-42')));
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('answer-42')))
          .controller!
          .text,
      'int score = 65;',
    );
    await tapKey(tester, 'practice-home');
    expect(find.byType(PracticalHomeScreen), findsOneWidget);
    expect(server.savedProgress!['completedAt'], isNull);
    GoRouter.of(tester.element(find.byType(PracticalHomeScreen)))
        .go('/practical/204/templates/31?section=311');
    await tester.pumpAndSettle();
    await tapText(tester, '다음');
    await reveal(tester, find.byKey(const ValueKey('answer-43')));
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('answer-43')))
          .controller!
          .text,
      '아직 제출하지 않은 설명',
    );
    await tester.tap(find.byTooltip('목차'));
    await tester.pumpAndSettle();
    expect(find.text('학습 목차'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('미제출·일부 제출 상태에서 다음 이동과 마지막 목록 복귀 후 미완료 문제를 다시 푼다', (
    tester,
  ) async {
    final server = _PracticalServer();
    await openSectionApp(
      tester,
      server,
      '/practical/204/templates/31?section=311',
    );
    await tapText(tester, '다음');
    await tapKey(tester, 'practice-next');
    expect(find.text('설명 319'), findsOneWidget);
    expect(server.savedProgress!['lastSectionId'], 319);
    expect(server.savedProgress!['completedAt'], isNull);
    await tapText(tester, '다음');
    await tapKey(tester, 'choice-81-B');
    await tapKey(tester, 'submit-81');
    await tapKey(tester, 'practice-next');
    expect(find.byType(PracticalHomeScreen), findsOneWidget);
    expect(server.savedProgress!['completedAt'], isNull);
    expect(server.saved.keys, [81]);
    // A fresh store restores submitted results from BE, without inventing the rest.
    await openSectionApp(
      tester,
      server,
      '/practical/204/templates/31?section=319',
    );
    await tapText(tester, '다음');
    expect(find.byKey(const ValueKey('result-81')), findsOneWidget);
    expect(find.byKey(const ValueKey('result-82')), findsNothing);
    await reveal(tester, find.byKey(const ValueKey('answer-82')));
    expect(
      tester.widget<TextField>(find.byKey(const ValueKey('answer-82'))).enabled,
      isTrue,
    );
    await enterAnswer(tester, 82, '새 코드 답안');
    await tapKey(tester, 'submit-82');
    expect(submissions(server, 81), 1);
    expect(submissions(server, 82), 1);
    expect(server.savedProgress!['completedAt'], isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('개요와 문제가 없는 하위 목차는 빈 문제 화면 없이 서버 목차 순서대로 이동한다', (tester) async {
    final server = _PracticalServer(withEmptySections: true);
    await openSectionApp(
      tester,
      server,
      '/practical/204/templates/31?section=300',
    );
    await tapText(tester, '다음');
    expect(find.text('설명 311'), findsOneWidget);
    expect(find.byType(LearningPracticeScreen), findsNothing);
    await tapText(tester, '다음');
    expect(find.byType(LearningPracticeScreen), findsOneWidget);
    await tapKey(tester, 'practice-next');
    expect(find.text('문제가 없는 본문 997'), findsOneWidget);
    await tapText(tester, '다음');
    expect(find.text('설명 319'), findsOneWidget);
    expect(find.byType(LearningPracticeScreen), findsNothing);
    await tapText(tester, '다음');
    await tapKey(tester, 'practice-next');
    expect(find.text('문제가 없는 본문 700'), findsOneWidget);
    await tapText(tester, '다음');
    expect(find.text('문제가 없는 본문 123'), findsOneWidget);
    await tapText(tester, '다음');
    expect(find.byType(PracticalHomeScreen), findsOneWidget);
    expect(server.savedProgress!['lastSectionId'], 123);
    expect(server.savedProgress!['completedAt'], isNull);
    expect(server.saved, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('모든 문제 채점 후 마지막에 문제가 없는 목차에서도 완료할 수 있다', (tester) async {
    final server = _PracticalServer(withEmptySections: true);
    await openSectionApp(
      tester,
      server,
      '/practical/204/templates/31?section=311',
    );
    await tapText(tester, '다음');
    await answerSection(tester, 40);
    await tapKey(tester, 'practice-next');
    await tapText(tester, '다음');
    await tapText(tester, '다음');
    await answerSection(tester, 80);
    await tapKey(tester, 'practice-next');
    expect(server.savedProgress!['completedAt'], isNull);
    await tapText(tester, '다음');
    await tapText(tester, '다음');
    expect(find.byType(PracticalHomeScreen), findsOneWidget);
    expect(server.savedProgress!['completedAt'], isNotNull);
    expect(server.savedProgress!['lastSectionId'], 123);
  });

  testWidgets('문제별 FAILED 재제출과 PENDING 결과 조회는 다른 문제를 제출하지 않는다', (tester) async {
    final server = _PracticalServer()
      ..pending = true
      ..failed = true;
    await openSectionApp(
      tester,
      server,
      '/practical/204/templates/31?section=311',
    );
    await tapText(tester, '다음');
    await enterAnswer(tester, 42, '코드 답안');
    await tapKey(tester, 'submit-42');
    expect(find.text('채점 결과 새로고침'), findsOneWidget);
    await enterAnswer(tester, 43, '설명 답안');
    await tapKey(tester, 'submit-43');
    expect(find.text('채점 서버 오류'), findsOneWidget);
    expect(find.text('이 문제 다시 제출'), findsOneWidget);
    server.failed = false;
    await tapKey(tester, 'submit-43');
    server.saved[42]!.addAll({
      'gradingStatus': 'COMPLETED',
      'score': 100,
      'gradedAt': stamp,
    });
    await tapKey(tester, 'submit-42');
    expect(submissions(server, 41), 0);
    expect(submissions(server, 42), 1);
    expect(submissions(server, 43), 2);
    await tapKey(tester, 'practice-next');
    expect(find.text('설명 319'), findsOneWidget);
    expect(server.savedProgress!['completedAt'], isNull);
  });

  testWidgets('채점 중 중복 클릭을 막고 다른 문제는 계속 입력할 수 있으며 실패 후 재시도한다', (tester) async {
    final server = _PracticalServer();
    final response = Completer<ResponseBody>();
    var hold = true;
    server.handle = (request) async {
      if (hold &&
          request.method == 'POST' &&
          request.path == '/api/questions/41/submissions') {
        return response.future;
      }
      return server.respond(request);
    };
    final store = await openSectionApp(
      tester,
      server,
      '/practical/204/templates/31?section=311',
    );
    await tapText(tester, '다음');
    await tapKey(tester, 'choice-41-B');
    final submit = find.byKey(const ValueKey('submit-41'));
    await reveal(tester, submit);
    await tester.tap(submit);
    await tester.pump();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(submissions(server, 41), 1);
    await reveal(tester, find.byKey(const ValueKey('answer-42')));
    expect(
      tester.widget<TextField>(find.byKey(const ValueKey('answer-42'))).enabled,
      isTrue,
    );
    await enterAnswer(tester, 42, '채점 중 작성한 답안');
    response.complete(jsonResponse({}, 500));
    await tester.pumpAndSettle();
    await reveal(tester, find.textContaining('입력한 답안은 유지됩니다'));
    expect(find.textContaining('입력한 답안은 유지됩니다'), findsOneWidget);
    hold = false;
    await tapKey(tester, 'submit-41');
    expect(submissions(server, 41), 2);
    expect(submissions(server, 42), 0);
    expect(store.practiceDraft(42), '채점 중 작성한 답안');
    store.bindUser(null);
    expect(store.practiceDraft(42), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('문제가 없는 목차의 문제 주소로 직접 들어가도 본문으로 이동한다', (tester) async {
    final server = _PracticalServer(withEmptySections: true);
    await openSectionApp(tester, server, '/learning-practice/31?section=997');
    expect(find.byType(LearningPracticeScreen), findsNothing);
    expect(find.byType(TemplatePreviewScreen), findsOneWidget);
    expect(find.text('설명 319'), findsOneWidget);
    expect(server.savedProgress!['completedAt'], isNull);
  });
}
