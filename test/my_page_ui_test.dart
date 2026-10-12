import 'package:cobip_app_fe/features/learning/presentation/template_preview_screen.dart';
import 'package:cobip_app_fe/features/problems/presentation/question_preview_screen.dart';
import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/features/my_page/presentation/my_page_screen.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_preview_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'auth_test_support.dart';

Future<void> selectTab(WidgetTester tester, int index) async {
  final tab = find.byType(Tab).at(index);
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

void main() {
  for (final (size, scale) in [
    (const Size(360, 800), 1.0),
    (const Size(320, 640), 2.0),
    (const Size(800, 600), 1.0),
    (const Size(640, 320), 1.0),
  ]) {
    testWidgets('마이페이지 모든 탭 $size 글자 $scale', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final router = createAppRouter(initialLocation: '/my-page');
      addTearDown(router.dispose);
      await tester.pumpLearningWidget(CobipApp(router: router));
      await tester.pumpAndSettle();
      expect(find.text('테스트학습자'), findsOneWidget);
      expect(find.text('1시간 7분'), findsNothing);
      expect(find.text('좋아요한 템플릿'), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      for (var i = 0; i < 4; i++) {
        await selectTab(tester, i);
        expect(tester.takeException(), isNull);
        for (var j = 0; j < 4; j++) {
          await tester.drag(
            find.byType(ListView).hitTestable().first,
            const Offset(0, -250),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
    });
  }

  testWidgets('실제 로컬 활동과 이어하기·제출 상세를 연결한다', (tester) async {
    final router = createAppRouter(initialLocation: '/my-page');
    addTearDown(router.dispose);
    await tester.pumpLearningWidget(CobipApp(router: router));
    await tester.pumpAndSettle();
    final store = tester
        .element(find.byType(MyPageScreen))
        .read<LearningPreviewStore>();
    final item = store.template(111)!;
    Future<void> finish(Future<dynamic> action) async {
      await tester.pump(const Duration(seconds: 1));
      await action;
      await tester.pumpAndSettle();
    }

    await finish(store.toggleBookmark(item.id));
    await finish(
      store.saveProgress(item.id, item.allSections.last.id, completed: true),
    );
    await finish(store.submit(2001, 'D'));
    await selectTab(tester, 1);
    expect(find.text('완료 1 / 시작한 학습 1'), findsOneWidget);
    expect(find.text('완료'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('복습하기 →'),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('my-learning')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('복습하기 →'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('복습하기 →'));
    await tester.pumpAndSettle();
    expect(find.byType(TemplatePreviewScreen), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    await selectTab(tester, 2);
    await tester.scrollUntilVisible(
      find.text('제출 내용 보기 →'),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('my-dashboard')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('제출 내용 보기 →'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제출 내용 보기 →'));
    await tester.pumpAndSettle();
    expect(find.byType(QuestionPreviewScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('활동 오류에서도 프로필을 유지하고 재시도한다', (tester) async {
    final router = createAppRouter(initialLocation: '/my-page');
    addTearDown(router.dispose);
    await tester.pumpLearningWidget(CobipApp(router: router));
    await tester.pumpAndSettle();
    final store = tester
        .element(find.byType(MyPageScreen))
        .read<LearningPreviewStore>();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    store.failNextAction = true;
    final load = store.load();
    await tester.pump();
    expect(find.text('활동 불러오는 중'), findsOneWidget);
    expect(find.text('테스트학습자'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await load;
    await tester.pumpAndSettle();
    expect(store.state, PreviewLoadState.error);
    await tester.scrollUntilVisible(
      find.text('활동을 불러오지 못했어요'),
      150,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('my-home')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('활동을 불러오지 못했어요'), findsOneWidget);
    await tester.ensureVisible(find.text('다시 시도'));
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('활동 요약'), findsOneWidget);
    await tester.tap(find.byTooltip('계정 관리'));
    await tester.pumpAndSettle();
    expect(find.text('닉네임: 테스트학습자'), findsOneWidget);
    await tester.tap(find.byTooltip('홈으로 돌아가기'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/home');
  });
}
