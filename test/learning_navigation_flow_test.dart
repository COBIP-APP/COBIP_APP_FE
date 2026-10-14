import 'dart:async';

import 'package:cobip_app_fe/features/learning/presentation/learning_practice_screen.dart';
import 'package:cobip_app_fe/features/learning/presentation/template_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'section_flow_test_support.dart';

class _OutlineServer extends SectionServer {
  _OutlineServer({required super.practical});

  @override
  List<Map<String, dynamic>> get sections => [
    {...super.sections.first, 'parentId': 300},
    {
      'id': 997,
      'parentId': 300,
      'title': '문제 없는 목차',
      'body': '중간 정리 본문',
      'media': [],
      'children': [],
    },
    {...super.sections.last, 'parentId': 300},
  ];

  @override
  Map<String, dynamic> get template => super.template
    ..['sections'] = [
      {
        'id': 300,
        'parentId': null,
        'title': '1. 개요',
        'body': '첫 개요 본문',
        'media': [],
        'children': sections,
      },
    ];
}

Future<void> tapNavigationKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  for (final practical in [false, true]) {
    final area = practical ? '실무' : '문법';
    final lesson = practical
        ? '/practical/204/templates/31'
        : '/grammar/java/chapters/31';
    final practice = practical
        ? '/learning-practice/31'
        : '/grammar-practice/31';
    final home = practical ? '/practical' : '/grammar/java/chapters';

    testWidgets('$area: 첫 본문 진입, 빈 문제 건너뛰기, 이전 단계와 홈 이동', (tester) async {
      final server = _OutlineServer(practical: practical);
      await openSectionApp(tester, server, lesson);
      final router = GoRouter.of(
        tester.element(find.byType(TemplatePreviewScreen)),
      );
      expect(find.text('첫 개요 본문'), findsOneWidget);
      expect(find.text('학습 목차'), findsNothing);
      expect(server.savedProgress!['lastSectionId'], 300);
      await tapText(tester, '다음');
      expect(find.text('설명 311'), findsOneWidget);
      await tapText(tester, '다음');
      expect(find.byType(LearningPracticeScreen), findsOneWidget);
      expect(find.text('학습으로 돌아가기'), findsNothing);
      expect(find.text('목차로 돌아가기'), findsNothing);
      await tapNavigationKey(tester, 'practice-next');
      expect(find.text('중간 정리 본문'), findsOneWidget);
      await tapNavigationKey(tester, 'lesson-next');
      expect(find.text('설명 319'), findsOneWidget);
      await tapNavigationKey(tester, 'lesson-previous');
      expect(find.text('중간 정리 본문'), findsOneWidget);
      await tapNavigationKey(tester, 'lesson-previous');
      expect(find.byType(LearningPracticeScreen), findsOneWidget);
      expect(server.savedProgress!['lastSectionId'], 311);
      await tapNavigationKey(tester, 'practice-previous');
      expect(find.text('설명 311'), findsOneWidget);
      final lessonUri = router.routeInformationProvider.value.uri;
      await tester.tap(find.byTooltip('목차'));
      await tester.pumpAndSettle();
      expect(find.text('학습 목차'), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(router.routeInformationProvider.value.uri, lessonUri);
      expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('section-311')))
            .selected,
        isTrue,
      );
      await tester.tap(find.byTooltip('목차 닫기'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('설명 311'), findsOneWidget);
      await tapNavigationKey(tester, 'lesson-home');
      expect(router.routeInformationProvider.value.uri.path, home);
      router.go(lesson);
      await tester.pumpAndSettle();
      expect(find.text('첫 개요 본문'), findsOneWidget);
      await tapNavigationKey(tester, 'lesson-previous');
      expect(router.routeInformationProvider.value.uri.path, home);
      expect(server.savedProgress!['completedAt'], isNull);
      expect(server.saved, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$area: 문제 목차 창을 닫으면 답안과 스크롤이 유지되고 선택하면 본문으로 이동한다', (
      tester,
    ) async {
      final server = SectionServer(practical: practical);
      final store = await openSectionApp(
        tester,
        server,
        '$practice?section=311',
      );
      final router = GoRouter.of(
        tester.element(find.byType(LearningPracticeScreen)),
      );
      final draft = find.byKey(const ValueKey('answer-42'));
      await reveal(tester, draft);
      await tester.enterText(draft, '목차를 열어도 유지할 답안');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      final offset = scroll.position.pixels;
      final uri = router.routeInformationProvider.value.uri;
      await tester.tap(find.byTooltip('목차'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(router.routeInformationProvider.value.uri, uri);
      await tester.tap(find.byTooltip('목차 닫기'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(router.routeInformationProvider.value.uri, uri);
      expect(scroll.position.pixels, offset);
      expect(
        tester.widget<TextField>(draft).controller!.text,
        '목차를 열어도 유지할 답안',
      );
      await tester.tap(find.byTooltip('목차'));
      await tester.pumpAndSettle();
      final destination = find.byKey(const ValueKey('section-319'));
      await tester.ensureVisible(destination);
      await tester.tap(destination);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('설명 319'), findsOneWidget);
      expect(store.practiceDraft(42), '목차를 열어도 유지할 답안');
      expect(server.savedProgress!['lastSectionId'], 319);
      expect(server.savedProgress!['completedAt'], isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$area: 한 문제 채점 중에도 이동하며 다른 답안과 늦게 온 결과를 유지한다', (tester) async {
      final server = SectionServer(practical: practical);
      final release = Completer<void>();
      server.handle = (request) async {
        if (request.method == 'POST' &&
            request.path == '/api/questions/41/submissions') {
          await release.future;
        }
        return server.respond(request);
      };
      final store = await openSectionApp(
        tester,
        server,
        '$practice?section=311',
      );
      final router = GoRouter.of(
        tester.element(find.byType(LearningPracticeScreen)),
      );
      final draft = find.byKey(const ValueKey('answer-42'));
      await reveal(tester, draft);
      await tester.enterText(draft, '아직 제출하지 않은 코드');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tapNavigationKey(tester, 'choice-41-B');
      await tapNavigationKey(tester, 'submit-41');
      await reveal(tester, find.byKey(const ValueKey('practice-next')));
      for (final key in [
        'practice-previous',
        'practice-home',
        'practice-next',
      ]) {
        expect(
          tester.widget<ButtonStyleButton>(find.byKey(ValueKey(key))).onPressed,
          isNotNull,
        );
      }
      await tapNavigationKey(tester, 'practice-next');
      expect(find.text('설명 319'), findsOneWidget);
      release.complete();
      await tester.pumpAndSettle();
      expect(store.latest(41)?.gradingStatus, 'COMPLETED');
      expect(server.saved.keys, [41]);
      await tapNavigationKey(tester, 'lesson-previous');
      expect(find.byType(LearningPracticeScreen), findsOneWidget);
      await reveal(tester, find.byKey(const ValueKey('result-41')));
      await reveal(tester, draft);
      expect(tester.widget<TextField>(draft).controller!.text, '아직 제출하지 않은 코드');
      expect(store.latest(42), isNull);
      await tapNavigationKey(tester, 'practice-home');
      expect(router.routeInformationProvider.value.uri.path, home);
      expect(server.savedProgress!['completedAt'], isNull);
      expect(tester.takeException(), isNull);
    });
  }
}
