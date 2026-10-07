import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const routes = [
    '/grammar',
    '/grammar/java/chapters',
    '/grammar/java/chapters/conditions',
    '/grammar/java/chapters/conditions/example',
    '/grammar/java/chapters/conditions/example/quiz',
    '/practical',
    '/practical/cache/chapters',
    '/practical/cache/chapters/basics',
    '/problems',
    '/problems/java-basics',
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
      await tester.pumpWidget(const CobipApp());
      for (final route in routes) {
        appRouter.go(route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: route);
        if (route == '/grammar/java/chapters/conditions') {
          expect(find.text('핵심 개념').hitTestable(), findsOneWidget);
          expect(
            tester.getTopLeft(find.text('예제 보기')).dy,
            greaterThan(size.height / 2),
          );
        }
        final lists = find.byType(Scrollable);
        if (lists.hitTestable().evaluate().isNotEmpty) {
          await tester.drag(lists.first.hitTestable(), const Offset(0, -400));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$route scrolled');
        }
      }
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.tap(find.byKey(const ValueKey('chat-input')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'chat keyboard');
      expect(find.byTooltip('메시지 보내기').hitTestable(), findsOneWidget);
      tester.view.resetViewInsets();
    });
  }
}
