import 'package:cobip_app_fe/features/learning/data/learning_models.dart';
import 'package:cobip_app_fe/features/learning/data/learning_preview_data.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_preview_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LearningPreviewStore store;
  setUp(() => store = LearningPreviewStore(delay: Duration.zero)..bindUser(1));
  tearDown(() => store.dispose());

  test('정답 기록은 이후 오답에도 유지되고 계정 변경 시 초기화된다', () async {
    final correct = previewAnswerKeys[2001]!;
    final wrong = correct == 'A' ? 'B' : 'A';
    store.failNextAction = true;
    await expectLater(store.submit(2001, correct), throwsStateError);
    expect(store.solved(2001), isFalse);
    expect(store.latest(2001), isNull);
    await store.submit(2001, wrong);
    expect(store.solved(2001), isFalse);
    await store.submit(2001, correct);
    expect(store.solved(2001), isTrue);
    await store.submit(2001, wrong);
    expect(store.latest(2001)!.score, 0);
    expect(store.solved(2001), isTrue);
    store.bindUser(2);
    expect(store.solved(2001), isFalse);
    expect(store.latest(2001), isNull);
  });

  test('목차 이동은 완료 상태를 보존하고 다시 학습은 완료를 해제한다', () async {
    await store.saveProgress(111, 11101, completed: true);
    final started = store.progress(111)!.startedAt;
    await store.saveProgress(111, 11103);
    expect(store.progress(111)!.lastSectionId, 11103);
    expect(store.progress(111)!.label, '완료');
    await store.saveProgress(111, 11101, completed: false);
    expect(store.progress(111)!.label, '학습 중');
    expect(store.progress(111)!.startedAt, started);
    await expectLater(store.saveProgress(111, 20101), throwsStateError);
    expect(store.progress(111)!.lastSectionId, 11101);
  });

  test('북마크 실패는 상태를 변경하지 않고 다시 시도할 수 있다', () async {
    store.failNextAction = true;
    await expectLater(store.toggleBookmark(111), throwsStateError);
    expect(store.bookmarked(111), isFalse);
    await store.toggleBookmark(111);
    expect(store.bookmarked(111), isTrue);
    await store.toggleBookmark(111);
    expect(store.bookmarked(111), isFalse);
  });

  test('객관식만 즉시 채점하고 서술·코드는 점수 없는 대기 상태다', () async {
    final choice = await store.submit(1000, previewAnswerKeys[1000]!);
    expect(choice.score, 100);
    expect(choice.gradingStatus, 'COMPLETED');
    expect(choice.gradingMethod, 'DB');
    expect(choice.answerText, isNull);
    expect(choice.sourceCode, isNull);
    for (final type in [
      LearningQuestionType.codeExplanation,
      LearningQuestionType.codeWriting,
    ]) {
      final question = store.questions.firstWhere(
        (q) => q.questionType == type,
      );
      final result = await store.submit(question.id, '직접 작성한 답안');
      expect(result.pending, isTrue);
      expect(result.score, isNull);
      expect(result.gradedAt, isNull);
      expect(store.latest(question.id), same(result));
    }
    expect(store.progress(111), isNull);
    await expectLater(store.submit(1000, '없는 선택지'), throwsStateError);
    await expectLater(store.submit(2000, '   '), throwsStateError);
  });

  test('계정 전환 시 기록과 이전 계정의 진행 중 요청을 버린다', () async {
    await store.toggleBookmark(111);
    await store.submit(1000, 'A');
    final pending = store.saveProgress(111, 11101);
    store.bindUser(2);
    await expectLater(pending, throwsStateError);
    expect(store.latest(1000), isNull);
    expect(store.bookmarked(111), isFalse);
    expect(store.progress(111), isNull);
  });

  test('학습 불러오기 실패 후 재시도와 빈 목록을 지원한다', () async {
    store.failNextAction = true;
    await store.load();
    expect(store.state, PreviewLoadState.error);
    await store.load();
    expect(store.state, PreviewLoadState.ready);
    final empty = LearningPreviewStore(
      templates: [],
      questions: [],
      delay: Duration.zero,
    );
    await empty.load();
    expect(empty.templates, isEmpty);
    empty.dispose();
  });
}
