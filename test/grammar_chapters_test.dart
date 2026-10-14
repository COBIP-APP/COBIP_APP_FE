import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_support.dart';

void main() {
  testWidgets('전체 보기는 문법 홈에서 언어·북마크·검색을 해제한다', (tester) async {
    final router = createAppRouter(initialLocation: '/grammar');
    addTearDown(router.dispose);
    await tester.pumpLearningWidget(CobipApp(router: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('필터'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Python'));
    await tester.tap(find.text('북마크만 보기'));
    await tester.tap(find.text('적용'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'elif');
    tester.testTextInput.hide();
    await tester.dragUntilVisible(
      find.text('전체 보기').hitTestable(),
      find.byType(ListView),
      const Offset(0, -150),
    );
    await tester.tap(find.text('전체 보기'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/grammar');
    expect(find.byTooltip('뒤로가기'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
    expect(find.text('전체 문법 챕터'), findsOneWidget);
    expect(find.text('전체 보기'), findsNothing);
    await tester.tap(find.byTooltip('필터'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '전체 언어'))
          .selected,
      isTrue,
    );
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });
  for (final language in ['java', 'python', 'common', 'unknown']) {
    testWidgets('기존 $language 목록 주소는 문법 홈으로 연결한다', (tester) async {
      final router = createAppRouter(
        initialLocation: '/grammar/$language/chapters',
      );
      addTearDown(router.dispose);
      await tester.pumpLearningWidget(CobipApp(router: router));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/grammar');
      expect(find.text('문법 학습'), findsOneWidget);
    });
  }
}
