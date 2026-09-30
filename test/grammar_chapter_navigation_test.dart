import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/features/grammar/presentation/grammar_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  for (final fromList in [false, true]) {
    for (final systemBack in [false, true]) {
      testWidgets('추가 챕터도 공통 이동 규칙을 따른다: 목록=$fromList, 기기 뒤로=$systemBack', (
        tester,
      ) async {
        // 조건문이 아닌 챕터를 등록해도 화면별 이동 코드를 바꿀 필요가 없습니다.
        grammarChapterRoutes['variables'] = GoRoute(
          path: 'variables',
          name: 'test-variables',
          builder: (context, state) => GrammarScaffold(
            title: '변수와 자료형',
            body: Text('${state.pathParameters['language']} 변수 상세'),
          ),
        );
        final router = createAppRouter(initialLocation: '/grammar');
        addTearDown(() {
          router.dispose();
          grammarChapterRoutes.remove('variables');
        });
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Python'));
        await tester.pumpAndSettle();
        if (fromList) {
          await tester.ensureVisible(find.text('전체 보기'));
          await tester.tap(find.text('전체 보기'));
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(find.text('변수와 자료형'));
        await tester.tap(find.text('변수와 자료형'));
        await tester.pumpAndSettle();
        expect(find.text('python 변수 상세'), findsOneWidget);
        expect(find.text('문법 챕터'), findsNothing);

        if (systemBack) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(find.byTooltip('뒤로가기'));
        }
        await tester.pumpAndSettle();
        expect(find.text('Python 문법'), findsOneWidget);
        expect(find.text('5개 챕터 · 예시 진행률'), findsOneWidget);
        expect(find.byType(ChoiceChip), findsNothing);

        await tester.tap(find.byTooltip('뒤로가기'));
        await tester.pumpAndSettle();
        expect(find.text('Python 문법 챕터'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
