import 'package:cobip_app_fe/features/practical/presentation/practical_home_screen.dart';
import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/features/practical/data/practical_sample_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_support.dart';

void main() {
  Future<void> open(WidgetTester tester, String path) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    appRouter.go(path);
    await tester.pumpLearningWidget(const CobipApp());
    await tester.pumpAndSettle();
  }

  testWidgets('실무 검색과 카테고리를 적용하고 탭을 전환한다', (tester) async {
    await open(tester, '/home');
    await tester.tap(find.text('실무'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    await tester.enterText(find.byType(TextField), 'Redis');
    await tester.pumpAndSettle();
    expect(find.text('캐시 관리와 Redis 활용'), findsOneWidget);
    expect(find.text('DB 인덱스와 쿼리 최적화'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'DB'));
    await tester.pumpAndSettle();
    expect(find.textContaining('검색 결과가 없어요'), findsOneWidget);
    await tester.tap(find.byTooltip('검색어 지우기'));
    await tester.pumpAndSettle();
    expect(find.text('DB 인덱스와 쿼리 최적화'), findsOneWidget);
    await tester.tap(find.text('문법'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('실무'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });

  testWidgets('주제에서 챕터에 진입하고 이전 다음 목록으로 이동한다', (tester) async {
    await open(tester, '/practical');
    await tester.ensureVisible(find.text('캐시 관리와 Redis 활용'));
    await tester.tap(find.text('캐시 관리와 Redis 활용'));
    await tester.pumpAndSettle();
    expect(find.text('챕터 목록'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('캐시 기본 개념'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '이전 챕터'))
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(find.text('다음 챕터'));
    await tester.tap(find.text('다음 챕터'));
    await tester.pumpAndSettle();
    expect(find.text('Redis 활용'), findsOneWidget);
    await tester.ensureVisible(find.text('이전 챕터'));
    await tester.tap(find.text('이전 챕터'));
    await tester.pumpAndSettle();
    expect(find.text('캐시 기본 개념'), findsOneWidget);
    await tester.tap(find.byTooltip('COBIA 챗봇'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('학습 계속하기'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('챕터 목록으로 돌아가기'));
    await tester.tap(find.text('챕터 목록으로 돌아가기'));
    await tester.pumpAndSettle();
    expect(find.text('챕터 목록'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    expect(find.text('학습 완료'), findsNothing);
    await tester.tap(find.byTooltip('실무 목록으로 돌아가기'));
    await tester.pumpAndSettle();
    expect(find.byType(PracticalHomeScreen), findsOneWidget);
  });

  testWidgets('모든 더미 챕터와 잘못된 주소를 안전하게 표시한다', (tester) async {
    await open(tester, '/practical');
    tester.view.physicalSize = const Size(320, 700);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final topic in practicalTopics) {
      for (final chapter in topic.chapters) {
        appRouter.go('/practical/${topic.id}/chapters/${chapter.id}');
        await tester.pumpAndSettle();
        expect(find.text(chapter.title), findsOneWidget);
        await tester.ensureVisible(find.text('챕터 목록으로 돌아가기'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '다음 챕터'))
            .onPressed,
        isNull,
      );
    }
    appRouter.go('/practical/cache/chapters/missing');
    await tester.pumpAndSettle();
    expect(find.text('챕터 목록'), findsOneWidget);
    appRouter.go('/practical/missing/chapters/basics');
    await tester.pumpAndSettle();
    expect(find.byType(PracticalHomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
