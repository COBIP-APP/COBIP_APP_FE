import 'dart:async';

import 'package:cobip_app_fe/features/my_page/presentation/question_delete_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('삭제 취소·중복 요청 방지·실패 후 재시도를 지원한다', (tester) async {
    var calls = 0;
    var opened = false;
    final pending = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InkWell(
            onTap: () => opened = true,
            child: QuestionDeleteButton(
              questionTitle: '내 문제',
              onDelete: () {
                calls++;
                return pending.future;
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '삭제'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(calls, 1);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
    await tester.tap(find.text('처리 중'));
    await tester.pump();
    expect(opened, isFalse);
    expect(calls, 1);
    pending.completeError(Exception('Unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('문제를 삭제하지 못했어요. 잠시 후 다시 시도해 주세요.'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNotNull,
    );
    expect(calls, 1);
  });
}
