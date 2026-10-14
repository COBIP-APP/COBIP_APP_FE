import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_store.dart';
import 'package:cobip_app_fe/features/learning/presentation/template_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'auth_test_support.dart';

void main() {
  const routes = [
    '/grammar',
    '/grammar/java/chapters',
    '/grammar/java/chapters/111',
    '/grammar/java/chapters/110',
    '/grammar/java/chapters/112',
    '/practical',
    '/practical/4/templates',
    '/practical/4/templates/201',
    '/problems',
    '/problems/generate',
    '/problems/2000',
    '/problems/2001',
    '/problems/2002',
    '/chat',
  ];
  for (final (size, scale) in [
    (const Size(360, 800), 1.0),
    (const Size(320, 640), 2.0),
    (const Size(800, 600), 1.0),
  ]) {
    testWidgets('학습 디자인 $size 글자 $scale', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final router = createAppRouter(initialLocation: routes.first);
      addTearDown(router.dispose);
      await tester.pumpLearningWidget(CobipApp(router: router));
      await tester.pumpAndSettle();
      for (final route in routes) {
        router.go(route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: route);
        final list = find.byType(ListView).first;
        for (var i = 0; i < 4; i++) {
          await tester.drag(list, const Offset(0, -400));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$route scrolled');
        }
      }
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      addTearDown(tester.view.resetViewInsets);
      await tester.tap(find.byKey(const ValueKey('chat-input')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('메시지 보내기').hitTestable(), findsOneWidget);
    });
  }
  for (final (size, scale, keyboard) in [
    (const Size(360, 800), 1.0, 280.0),
    (const Size(320, 640), 2.0, 240.0),
    (const Size(640, 320), 1.0, 140.0),
  ]) {
    testWidgets('문제 결과와 학습 챗봇 키보드 $size 글자 $scale', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final router = createAppRouter(
        initialLocation: '/grammar/java/chapters/111',
      );
      addTearDown(router.dispose);
      await tester.pumpLearningWidget(CobipApp(router: router));
      await tester.pumpAndSettle();
      final chatButton = find.byTooltip('COBIA 챗봇');
      final chatBounds = tester.getRect(chatButton);
      expect(
        chatBounds.top,
        greaterThanOrEqualTo(tester.getBottomLeft(find.byType(AppBar)).dy),
      );
      expect(chatBounds.right, greaterThan(size.width / 2));
      final bodyBounds = tester.getRect(find.byType(ListView).first);
      expect(chatBounds.top, greaterThan(bodyBounds.top));
      expect(chatBounds.top - bodyBounds.top, lessThanOrEqualTo(24));
      expect(bodyBounds.top, tester.getBottomLeft(find.byType(AppBar)).dy);
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.getRect(chatButton), chatBounds);
      await tester.tap(find.byTooltip('목차'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView).last, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('목차 닫기'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('COBIA 챗봇'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
      await tester.tap(find.byKey(const ValueKey('chat-input')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('메시지 보내기').hitTestable(), findsOneWidget);
      tester.view.resetViewInsets();
      await tester.tap(find.byTooltip('챗봇 닫기'));
      await tester.pumpAndSettle();
      final store = tester
          .element(find.byType(TemplatePreviewScreen))
          .read<LearningStore>();
      for (final (id, answer) in [(2000, '직접 작성한 코드\nprint(1)'), (2001, 'D')]) {
        final pending = store.submit(id, answer);
        await tester.pump(const Duration(seconds: 1));
        await pending;
        router.go('/problems/$id');
        await tester.pumpAndSettle();
        expect(find.byTooltip('COBIA 챗봇'), findsNothing);
        final recentResult = find.text('최근 제출 결과 보기');
        await tester.dragUntilVisible(
          recentResult.hitTestable(),
          find.byType(ListView).first,
          const Offset(0, -150),
        );
        await tester.tap(recentResult);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (var i = 0; i < 5; i++) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -250));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
    });
  }
}
