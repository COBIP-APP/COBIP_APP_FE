import 'package:flutter/foundation.dart';

import '../data/learning_models.dart';
import '../data/learning_preview_data.dart';

enum PreviewLoadState { loading, ready, error }

// Local-only UI rehearsal. No API, database, or persistent storage writes.
class LearningPreviewStore extends ChangeNotifier {
  LearningPreviewStore({
    List<LearningTemplate>? templates,
    List<LearningQuestion>? questions,
    this.delay = const Duration(milliseconds: 180),
  }) : templates = templates ?? previewTemplates,
       questions = questions ?? previewQuestions;
  final List<LearningTemplate> templates;
  final List<LearningQuestion> questions;
  final Duration delay;
  final _progress = <int, LearningProgress>{};
  final _bookmarks = <int>{};
  final _submissions = <int, LearningSubmission>{};
  int? _userId;
  int _generation = 0;
  int _submissionId = 0;
  bool _disposed = false;
  bool failNextAction = false;
  PreviewLoadState state = PreviewLoadState.loading;

  void bindUser(int? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _generation++;
    _progress.clear();
    _bookmarks.clear();
    _submissions.clear();
  }

  Future<void> load() async {
    state = PreviewLoadState.loading;
    notifyListeners();
    try {
      await _wait();
      if (_disposed) return;
      state = PreviewLoadState.ready;
    } catch (_) {
      if (_disposed) return;
      state = PreviewLoadState.error;
    }
    notifyListeners();
  }

  Future<void> _wait() async {
    final generation = _generation;
    await Future<void>.delayed(delay);
    if (_disposed || generation != _generation) {
      throw StateError('Session changed');
    }
    if (failNextAction) {
      failNextAction = false;
      throw StateError('Preview failure');
    }
  }

  LearningTemplate? template(int id) =>
      templates.where((t) => t.id == id).firstOrNull;
  LearningQuestion? question(int id) =>
      questions.where((q) => q.id == id).firstOrNull;
  LearningProgress? progress(int id) => _progress[id];
  bool bookmarked(int id) => _bookmarks.contains(id);
  LearningSubmission? latest(int id) => _submissions[id];

  Future<void> toggleBookmark(int id) async {
    await _wait();
    if (template(id) == null) throw StateError('Unknown template');
    if (!_bookmarks.remove(id)) _bookmarks.add(id);
    notifyListeners();
  }

  Future<void> saveProgress(
    int templateId,
    int sectionId, {
    bool? completed,
  }) async {
    await _wait();
    final item = template(templateId);
    if (item == null || !item.allSections.any((s) => s.id == sectionId)) {
      throw StateError('Section does not belong to template');
    }
    final previous = _progress[templateId];
    final now = DateTime.now();
    _progress[templateId] = LearningProgress(
      templateId: templateId,
      lastSectionId: sectionId,
      startedAt: previous?.startedAt ?? now,
      lastStudiedAt: now,
      completedAt: completed == null
          ? previous?.completedAt
          : completed
          ? previous?.completedAt ?? now
          : null,
    );
    notifyListeners();
  }

  Future<LearningSubmission> submit(int questionId, String answer) async {
    final item = question(questionId);
    if (item == null || answer.trim().isEmpty) {
      throw StateError('Invalid answer');
    }
    if (item.questionType == LearningQuestionType.multipleChoice &&
        !item.choiceOptions.any((c) => c.key == answer)) {
      throw StateError('Invalid choice');
    }
    await _wait();
    final now = DateTime.now();
    final isChoice = item.questionType == LearningQuestionType.multipleChoice;
    final correct = previewAnswerKeys[questionId] == answer;
    final result = LearningSubmission(
      id: ++_submissionId,
      questionId: questionId,
      gradingStatus: isChoice ? 'COMPLETED' : 'PENDING',
      gradingMethod: isChoice ? 'DB' : null,
      submittedAt: now,
      gradedAt: isChoice ? now : null,
      selectedChoiceKey: isChoice ? answer : null,
      answerText: item.questionType == LearningQuestionType.codeExplanation
          ? answer
          : null,
      sourceCode: item.questionType == LearningQuestionType.codeWriting
          ? answer
          : null,
      score: isChoice
          ? correct
                ? 100
                : 0
          : null,
      feedback: isChoice
          ? correct
                ? '정답입니다.'
                : '답안을 다시 확인해 보세요.'
          : null,
    );
    _submissions[questionId] = result;
    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
