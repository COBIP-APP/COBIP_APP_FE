import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/features/learning/data/learning_api.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_preview_widgets.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_support.dart';
import 'learning_test_support.dart';

void main() {
  for (final count in [5, 6, 11]) {
    testWidgets('$count개 문제를 5개씩 표시하고 검색하면 첫 페이지로 돌아간다', (tester) async {
      final server = LearningServer();
      server.handle = (r) async => r.path == '/api/questions'
          ? jsonResponse([
              for (var i = 1; i <= count; i++)
                serverQuestion(41)..addAll({'id': i, 'prompt': '페이지 문제 $i'}),
            ], 200)
          : server.respond(r);
      final auth = await tester.runAsync(
        () => testAuth(authenticated: true, adapter: server),
      );
      addTearDown(auth!.dispose);
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
      List<int> shownIds() =>
          (tester.widget<ListView>(find.byType(ListView).first).childrenDelegate
                  as SliverChildListDelegate)
              .children
              .whereType<QuestionPreviewCard>()
              .map((w) => w.item.id)
              .toList();
      expect(shownIds(), [1, 2, 3, 4, 5]);
      if (count > 5) {
        await tester.dragUntilVisible(
          find.byKey(const ValueKey('problem-page-2')).hitTestable(),
          find.byType(ListView).first,
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();
      }
      expect(
        find.byKey(const ValueKey('problem-pagination')),
        count > 5 ? findsOneWidget : findsNothing,
      );
      if (count > 5) {
        await tester.tap(find.byKey(const ValueKey('problem-page-2')));
        await tester.pumpAndSettle();
        expect(shownIds(), count == 6 ? [6] : [6, 7, 8, 9, 10]);
        if (count == 11) {
          await tester.dragUntilVisible(
            find.byTooltip('다음 페이지').hitTestable(),
            find.byType(ListView).first,
            const Offset(0, -300),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('다음 페이지'));
          await tester.pumpAndSettle();
          expect(shownIds(), [11]);
        }
        await tester.enterText(find.byType(TextField).first, '페이지 문제 2');
        await tester.pumpAndSettle();
        expect(shownIds(), [2]);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
