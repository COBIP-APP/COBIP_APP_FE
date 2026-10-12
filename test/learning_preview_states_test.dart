import 'preview_learning_store.dart';

import 'package:cobip_app_fe/features/grammar/presentation/grammar_home_screen.dart';
import 'package:cobip_app_fe/features/learning/data/learning_models.dart';
import 'package:cobip_app_fe/features/learning/data/learning_preview_data.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_store.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_preview_widgets.dart';
import 'package:cobip_app_fe/features/problems/presentation/submission_preview_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('로딩 실패는 재시도 후 빈 목록 안내로 복구한다', (tester) async {
    final store = PreviewLearningStore(
      templates: [],
      questions: [],
      delay: const Duration(milliseconds: 20),
    );
    addTearDown(store.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<LearningStore>.value(
        value: store,
        child: const MaterialApp(home: GrammarHomeScreen()),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    store.failNextAction = true;
    final failed = store.load();
    await tester.pumpAndSettle();
    await failed;
    expect(find.text('학습 정보를 불러오지 못했어요.'), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.textContaining('아직 등록된 학습이 없어요').hitTestable(),
      find.byType(ListView),
      const Offset(0, -150),
    );
    expect(find.textContaining('아직 등록된 학습이 없어요'), findsOneWidget);
  });

  testWidgets('채점 실패를 0점이나 채점 완료로 표시하지 않는다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SubmissionPreviewResult(
              question: previewQuestions.first,
              submission: LearningSubmission(
                id: 1,
                questionId: previewQuestions.first.id,
                gradingStatus: 'FAILED',
                submittedAt: DateTime(2026, 10, 11),
                selectedChoiceKey: 'A',
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('채점 실패'), findsOneWidget);
    expect(find.text('0점'), findsNothing);
    expect(find.text('채점 완료'), findsNothing);
  });

  testWidgets('첨부 objectKey는 네트워크 이미지 주소로 사용하지 않는다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PreviewMediaList(
            items: [
              LearningMedia(
                id: 1,
                originalName: 'diagram.png',
                objectKey: 'private/key.png',
                altText: '캐시 흐름',
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.textContaining('캐시 흐름'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.textContaining('private/key.png'), findsNothing);
  });
}
