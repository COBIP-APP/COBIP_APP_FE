import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/app/widgets/progressive_card_list.dart';
import 'package:cobip_app_fe/app/widgets/app_home_header.dart';
import 'package:cobip_app_fe/features/learning/data/learning_api.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_support.dart';
import 'learning_test_support.dart';

void main() {
  for (final count in [5, 7, 20]) {
    testWidgets('$count개 문제를 스크롤로 5개씩 추가하고 고정 헤더·맨 위로·검색 초기화를 지원한다', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final server = LearningServer();
      server.handle = (r) async => r.path == '/api/questions'
          ? jsonResponse([
              for (var i = 1; i <= count; i++)
                standaloneQuestion(41)
                  ..addAll({'id': i, 'prompt': '페이지 문제 $i'}),
            ], 200)
          : server.respond(r);
      final auth = (await tester.runAsync(
        () => testAuth(authenticated: true, adapter: server),
      ))!;
      addTearDown(auth.dispose);
      final router = createAppRouter(initialLocation: '/problems');
      addTearDown(router.dispose);
      await tester.pumpWithAuth(
        CobipApp(
          router: router,
          learningStore: LearningStore(api: LearningApi(auth.api.dio)),
        ),
        auth: auth,
      );
      await tester.pumpAndSettle();
      int listChildren() {
        final list = tester.widget<ProgressiveCardList>(
          find.byType(ProgressiveCardList),
        );
        final count = tester
            .widget<ListView>(find.byType(ListView))
            .childrenDelegate
            .estimatedChildCount!;
        return count - list.header.length;
      }

      // Only five cards and, when needed, a loading footer are initially listed.
      expect(listChildren(), 5 + (count > 5 ? 1 : 0));
      final headerY = tester.getTopLeft(find.byType(AppHomeHeader)).dy;
      await tester.drag(find.byType(ListView), const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(listChildren(), 5 + (count > 5 ? 1 : 0));
      expect(find.textContaining('개 표시'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('페이지 문제 $count'),
        250,
        scrollable: find.byType(Scrollable).first,
        duration: const Duration(milliseconds: 100),
        maxScrolls: 100,
      );
      await tester.pumpAndSettle();
      expect(listChildren(), count);
      expect(find.textContaining('모두 표시'), findsNothing);
      expect(tester.getTopLeft(find.byType(AppHomeHeader)).dy, headerY);
      expect(find.byTooltip('맨 위로'), findsOneWidget);
      await tester.tap(find.byTooltip('맨 위로'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('맨 위로'), findsNothing);
      await tester.enterText(find.byType(TextField), '페이지 문제 3');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ProgressiveCardList>(find.byType(ProgressiveCardList))
            .items
            .length,
        1,
      );
      expect(tester.takeException(), isNull);
    });
  }

  Widget cardList({String resetKey = 'all'}) => MaterialApp(
    home: Scaffold(
      body: ProgressiveCardList(
        resetKey: resetKey,
        items: [
          for (var i = 1; i <= 15; i++)
            SizedBox(height: 60, child: Text('카드 $i')),
        ],
      ),
    ),
  );

  int childCount(WidgetTester tester) => tester
      .widget<ListView>(find.byType(ListView))
      .childrenDelegate
      .estimatedChildCount!;

  testWidgets('다음 카드 표시 전 최소 0.7초 로딩을 보여주고 중복 요청을 막는다', (tester) async {
    await tester.pumpWidget(cardList());
    await tester.tap(find.text('다음 5개 더 보기'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(childCount(tester), 6);
    await tester.pump(const Duration(milliseconds: 699));
    expect(find.text('불러오는 중…'), findsOneWidget);
    expect(childCount(tester), 6);
    // Repeated downward scrolling during the delay must not queue more batches.
    await tester.drag(find.byType(ListView), const Offset(0, -100));
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(childCount(tester), 11);
    await tester.pumpAndSettle();
    expect(childCount(tester), 11);
    expect(tester.takeException(), isNull);
  });

  testWidgets('필터 변경과 화면 종료는 대기 중인 카드 추가를 취소한다', (tester) async {
    await tester.pumpWidget(cardList());
    await tester.tap(find.text('다음 5개 더 보기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(cardList(resetKey: 'filtered'));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(childCount(tester), 6);
    await tester.tap(find.text('다음 5개 더 보기'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
  });
}
