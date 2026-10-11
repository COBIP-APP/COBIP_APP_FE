import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_support.dart';

void main() {
  testWidgets('전체 목록을 열고 돌아오면 검색과 언어를 유지한다', (tester) async {
    final router = createAppRouter(initialLocation: '/grammar');
    addTearDown(router.dispose);
    await tester.pumpLearningWidget(CobipApp(router: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Python'));
    await tester.enterText(find.byType(TextField), 'elif');
    tester.testTextInput.hide();
    await tester.dragUntilVisible(
      find.text('전체 보기').hitTestable(),
      find.byType(ListView),
      const Offset(0, -150),
    );
    await tester.tap(find.text('전체 보기'));
    await tester.pumpAndSettle();
    expect(find.text('Python 문법'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'elif',
    );
    expect(find.text('Python 문법 챕터'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('잘못된 언어는 문법 목록으로 복귀한다', (tester) async {
    final router = createAppRouter(
      initialLocation: '/grammar/unknown/chapters',
    );
    addTearDown(router.dispose);
    await tester.pumpLearningWidget(CobipApp(router: router));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/grammar');
    expect(find.text('문법 학습'), findsOneWidget);
  });
}
