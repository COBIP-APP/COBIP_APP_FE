import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/features/learning/data/learning_api.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_support.dart';
import 'learning_test_support.dart';

class SectionServer extends LearningServer {
  SectionServer({this.practical = false});
  final bool practical;
  bool failed = false, pending = false, noQuestions = false;
  Map<String, dynamic> get template => serverTemplate()
    ..addAll({
      'categoryId': practical ? 204 : 201,
      'sections': [
        for (final id in [311, 319])
          {
            'id': id,
            'parentId': null,
            'title': '목차 $id',
            'body': '설명 $id',
            'exampleCode': 'int value = $id;',
            'media': [],
            'children': [],
          },
      ],
    });
  @override
  Future<ResponseBody> respond(RequestOptions r) async {
    if (r.path == '/api/templates') return jsonResponse([template], 200);
    if (r.path == '/api/templates/31') return jsonResponse(template, 200);
    if (r.path == '/api/questions') {
      return jsonResponse([
        if (!noQuestions)
          for (final base in [40, 80])
            for (var i = 1; i <= 3; i++)
              serverQuestion(40 + i)..addAll({
                'id': base + i,
                'prompt': '목차 문제 ${base + i}',
                'relatedSectionId': base == 40 ? 311 : 319,
              }),
      ], 200);
    }
    if (r.path.endsWith('/submissions') && r.method == 'POST') {
      final id = int.parse(r.path.split('/')[3]);
      final status = id == 43 && failed
          ? 'FAILED'
          : id == 42 && pending
          ? 'PENDING'
          : 'COMPLETED';
      saved[id] = {
        'id': nextId++,
        'userId': 1,
        'questionId': id,
        ...r.data as Map,
        'gradingStatus': status,
        'gradingMethod': status == 'COMPLETED' ? 'AI' : null,
        'score': status == 'COMPLETED' ? (id == 41 ? 0 : 100) : null,
        'feedback': status == 'FAILED' ? '채점 서버 오류' : '채점 피드백',
        'submittedAt': stamp,
        'gradedAt': status == 'COMPLETED' ? stamp : null,
      };
      return jsonResponse(saved[id], 201);
    }
    return super.respond(r);
  }
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String label) async {
  await reveal(tester, find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<LearningStore> openSectionApp(
  WidgetTester tester,
  SectionServer server,
  String path,
) async {
  final auth = (await tester.runAsync(
    () => testAuth(authenticated: true, adapter: server),
  ))!;
  addTearDown(auth.dispose);
  final store = LearningStore(api: LearningApi(auth.api.dio));
  final router = createAppRouter(initialLocation: path);
  addTearDown(router.dispose);
  await tester.pumpWithAuth(
    CobipApp(router: router, learningStore: store),
    auth: auth,
  );
  await tester.pumpAndSettle();
  return store;
}

Future<void> answerSection(WidgetTester tester, int base) async {
  final choice = find.byKey(ValueKey('choice-${base + 1}-B'));
  await reveal(tester, choice);
  await tester.tap(choice);
  await tester.pumpAndSettle();
  for (final id in [base + 2, base + 3]) {
    final field = find.byKey(ValueKey('answer-$id'));
    await reveal(tester, field);
    await tester.enterText(field, '답안 $id');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
  }
  await tapText(tester, '답 확인');
}

Future<void> verifySectionFlow(
  WidgetTester tester, {
  required bool practical,
}) async {
  final server = SectionServer(practical: practical);
  final path = practical
      ? '/practical/204/templates/31'
      : '/grammar/java/chapters/31';
  final store = await openSectionApp(tester, server, path);
  expect(find.text('학습 목차'), findsOneWidget);
  expect(server.savedProgress, isNull);
  await tapText(tester, '목차 311');
  expect(server.savedProgress!['lastSectionId'], 311);
  expect(find.text('설명 311'), findsOneWidget);
  await tapText(tester, '다음');
  expect(find.text('목차 문제 81'), findsNothing);
  await answerSection(tester, 40);
  expect(store.latest(41)!.score, 0);
  expect(server.savedProgress!['completedAt'], isNull);
  await tapText(tester, '다음');
  expect(find.text('설명 319'), findsOneWidget);
  expect(server.savedProgress!['lastSectionId'], 319);
  expect(server.savedProgress!['completedAt'], isNull);
  await tapText(tester, '다음');
  expect(find.text('목차 문제 41'), findsNothing);
  await answerSection(tester, 80);
  server.failure = 500;
  server.failurePath = '/api/users/1/progress/templates/31';
  await tapText(tester, '다음');
  expect(server.savedProgress!['completedAt'], isNull);
  expect(find.text('학습 진도를 저장하지 못했어요. 다시 눌러 주세요.'), findsOneWidget);
  server.failure = null;
  await tapText(tester, '다음');
  expect(server.savedProgress!['completedAt'], isNotNull);
  expect(server.savedProgress!['lastSectionId'], 319);
  expect(
    server.requests
        .where((r) => r.method == 'POST' && r.path.endsWith('/submissions'))
        .length,
    6,
  );
  expect(tester.takeException(), isNull);
}
