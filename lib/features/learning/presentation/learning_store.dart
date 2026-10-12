import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/learning_api.dart';
import '../data/learning_models.dart';
import '../../problems/data/ai_models.dart';

enum PreviewLoadState { loading, ready, error }

/// Server-backed data, scoped to one authenticated user. No sample fallback.
class LearningStore extends ChangeNotifier {
  LearningStore({required this.api});
  final LearningApi api;
  List<LearningLanguage> _languages = [];
  List<LearningCategory> _categories = [];
  List<LearningTemplate> _templates = [];
  List<LearningQuestion> _questions = [];
  List<LearningQuestion> _myQuestions = [];
  int _saveVersion = 0;
  final _saveVersions = <int, int>{};
  PreviewLoadState? myQuestionsState;
  String? myQuestionsError;
  List<LearningQuestion> get myQuestions => _myQuestions;
  List<LearningLanguage> get languages => _languages;
  List<LearningCategory> get categories => _categories;
  List<LearningTemplate> get templates => _templates;
  List<LearningQuestion> get questions => {
    for (final q in _questions) q.id: q,
    for (final q in _myQuestions) q.id: q,
  }.values.toList();
  final _progress = <int, LearningProgress>{};
  final _bookmarks = <int>{};
  final _submissions = <int, LearningSubmission>{};
  // BE exposes latest only: past passes discovered this session remain marked.
  final _solved = <int>{};
  final _details = <String, PreviewLoadState>{};
  final _detailErrors = <String, String>{};
  final _busy = <String>{};
  int? _userId;
  int _generation = 0;
  bool _disposed = false;
  bool _loading = false;
  bool _refreshRequested = false;
  CancelToken _cancel = CancelToken();
  PreviewLoadState state = PreviewLoadState.loading;
  String? error;
  int? get userId => _userId;
  bool _current(int generation) => !_disposed && generation == _generation;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void bindUser(int? userId) {
    if (_userId == userId) return;
    _cancel.cancel('Session changed');
    _cancel = CancelToken();
    _userId = userId;
    final generation = ++_generation;
    _loading = false;
    _refreshRequested = false;
    _languages = [];
    _categories = [];
    _templates = [];
    _questions = [];
    _myQuestions = [];
    _saveVersions.clear();
    _saveVersion = 0;
    myQuestionsState = null;
    myQuestionsError = null;
    _progress.clear();
    _bookmarks.clear();
    _submissions.clear();
    _solved.clear();
    _details.clear();
    _detailErrors.clear();
    _busy.clear();
    state = PreviewLoadState.loading;
    error = null;
    // Provider updates may occur during build; notify and load on the next turn.
    scheduleMicrotask(() {
      if (_current(generation)) {
        if (userId != null) {
          load();
        } else {
          _notify();
        }
      }
    });
  }

  Future<List<T>> _batch<I, T>(
    List<I> input,
    Future<T> Function(I) run,
    int generation,
  ) async {
    final results = <T>[];
    for (var i = 0; i < input.length; i += 4) {
      if (!_current(generation)) throw StateError('Session changed');
      results.addAll(await Future.wait(input.skip(i).take(4).map(run)));
    }
    return results;
  }

  Future<void> load() async {
    final userId = _userId;
    if (userId == null ||
        _disposed ||
        _loading ||
        _busy.isNotEmpty ||
        _details.containsValue(PreviewLoadState.loading)) {
      return;
    }
    final generation = _generation;
    final cancel = _cancel;
    _loading = true;
    state = PreviewLoadState.loading;
    error = null;
    _notify();
    try {
      final languages = await api.languages(cancelToken: cancel);
      final categories = await api.categories(cancelToken: cancel);
      final templates = await api.templates(cancelToken: cancel);
      final questions = await api.questions(cancelToken: cancel);
      final progress = await api.progress(cancelToken: cancel);
      final bookmarks = await api.bookmarks(userId, cancelToken: cancel);
      final visibleQuestions = {
        for (final q in questions) q.id: q,
        for (final q in _myQuestions) q.id: q,
      }.values.toList();
      final submissions = await _batch(
        visibleQuestions,
        (q) => api.latest(userId, q.id, cancelToken: cancel),
        generation,
      );
      if (!_current(generation)) return;
      _languages = languages;
      _categories = categories;
      _templates = templates;
      _questions = questions;
      _progress
        ..clear()
        ..addEntries(progress.map((p) => MapEntry(p.templateId, p)));
      _bookmarks
        ..clear()
        ..addAll(bookmarks);
      _submissions
        ..clear()
        ..addEntries(
          submissions.whereType<LearningSubmission>().map(
            (s) => MapEntry(s.questionId, s),
          ),
        );
      for (final q in visibleQuestions) {
        final s = _submissions[q.id];
        if (_passed(q, s)) _solved.add(q.id);
      }
      _details.clear();
      _detailErrors.clear();
      state = PreviewLoadState.ready;
    } catch (e) {
      if (!_current(generation)) return;
      error = e is LearningApiException ? e.message : '학습 정보를 불러오지 못했어요.';
      state = PreviewLoadState.error;
    } finally {
      if (_current(generation)) {
        _loading = false;
        _notify();
        _drainRefresh();
      }
    }
  }

  bool detailReady(String key) => _details[key] == PreviewLoadState.ready;

  /// Reload after another screen saved activity, including during an old read.
  void requestRefresh() {
    if (_disposed || _userId == null) return;
    _refreshRequested = true;
    _drainRefresh();
  }

  void _drainRefresh() {
    if (!_refreshRequested ||
        _disposed ||
        _userId == null ||
        _loading ||
        _busy.isNotEmpty ||
        _details.containsValue(PreviewLoadState.loading)) {
      return;
    }
    _refreshRequested = false;
    unawaited(load());
  }

  Future<void> loadMyQuestions() async {
    final user = _userId;
    if (user == null ||
        _disposed ||
        myQuestionsState == PreviewLoadState.loading) {
      return;
    }
    final generation = _generation;
    final saveVersion = _saveVersion;
    final cancel = _cancel;
    myQuestionsState = PreviewLoadState.loading;
    myQuestionsError = null;
    _notify();
    try {
      final items = await api.myQuestions(user, cancelToken: cancel);
      final submissions = await _batch(
        items,
        (q) => api.latest(user, q.id, cancelToken: cancel),
        generation,
      );
      if (!_current(generation)) return;
      _myQuestions = {
        for (final q in items) q.id: q,
        for (final q in _myQuestions)
          if ((_saveVersions[q.id] ?? 0) > saveVersion) q.id: q,
      }.values.toList();
      for (var i = 0; i < items.length; i++) {
        final s = submissions[i];
        if (s == null) {
          _submissions.remove(items[i].id);
        } else {
          _submissions[items[i].id] = s;
        }
        if (_passed(items[i], s)) _solved.add(items[i].id);
      }
      myQuestionsState = PreviewLoadState.ready;
    } catch (e) {
      if (!_current(generation)) return;
      myQuestionsState = PreviewLoadState.error;
      myQuestionsError = e is LearningApiException
          ? e.message
          : '내가 만든 문제를 불러오지 못했어요.';
    }
    if (_current(generation)) _notify();
  }

  Future<LearningQuestion> saveGeneratedQuestion({
    required String clientRequestId,
    required AiQuizBatch batch,
    required AiQuiz quiz,
  }) => _mutate(
    'save:$clientRequestId',
    (u, c) => api.saveGeneratedQuestion(
      userId: u,
      clientRequestId: clientRequestId,
      batch: batch,
      quiz: quiz,
      cancelToken: c,
    ),
    (question) {
      _saveVersions[question.id] = ++_saveVersion;
      _myQuestions = [
        question,
        ..._myQuestions.where((q) => q.id != question.id),
      ];
    },
  );
  String? detailError(String key) => _detailErrors[key];
  Future<void> ensureDetail(String key, {bool refresh = false}) async {
    if (state != PreviewLoadState.ready ||
        _userId == null ||
        _disposed ||
        _details[key] == PreviewLoadState.loading ||
        (!refresh && _details.containsKey(key))) {
      return;
    }
    final generation = _generation;
    final userId = _userId!;
    final cancel = _cancel;
    _details[key] = PreviewLoadState.loading;
    _detailErrors.remove(key);
    _notify();
    final id = int.parse(key.substring(2));
    try {
      if (key.startsWith('t:')) {
        final item = await api.template(id, cancelToken: cancel);
        if (!_current(generation)) return;
        _templates = [
          for (final t in _templates)
            if (t.id == id) item else t,
          if (!_templates.any((t) => t.id == id)) item,
        ];
      } else {
        final item = await api.question(
          id,
          ownerId: userId,
          cancelToken: cancel,
        );
        final latest = await api.latest(userId, id, cancelToken: cancel);
        if (!_current(generation)) return;
        if (item.createdBy == userId) {
          _myQuestions = [
            for (final q in _myQuestions)
              if (q.id == id) item else q,
          ];
        }
        _questions = [
          for (final q in _questions)
            if (q.id == id) item else q,
          if (!_questions.any((q) => q.id == id)) item,
        ];
        if (latest == null) {
          _submissions.remove(id);
        } else {
          _submissions[id] = latest;
        }
        if (_passed(item, latest)) _solved.add(id);
      }
      _details[key] = PreviewLoadState.ready;
    } catch (e) {
      if (!_current(generation)) return;
      _details[key] = PreviewLoadState.error;
      _detailErrors[key] = e is LearningApiException
          ? e.message
          : '상세 정보를 불러오지 못했어요.';
    }
    if (_current(generation)) {
      _notify();
      _drainRefresh();
    }
  }

  LearningTemplate? template(int id) =>
      templates.where((t) => t.id == id).firstOrNull;
  LearningQuestion? question(int id) =>
      questions.where((q) => q.id == id).firstOrNull;
  LearningProgress? progress(int id) => _progress[id];
  bool bookmarked(int id) => _bookmarks.contains(id);
  LearningSubmission? latest(int id) => _submissions[id];
  bool solved(int id) => _solved.contains(id);
  bool _passed(LearningQuestion q, LearningSubmission? s) =>
      s?.gradingStatus == 'COMPLETED' &&
      s?.score != null &&
      s!.score! >= q.passScore;

  Future<T> _mutate<T>(
    String key,
    Future<T> Function(int, CancelToken) request,
    void Function(T) accept,
  ) async {
    final user = _userId;
    if (user == null ||
        _disposed ||
        state != PreviewLoadState.ready ||
        !_busy.add(key)) {
      throw StateError('Action unavailable');
    }
    final generation = _generation;
    try {
      final result = await request(user, _cancel);
      if (!_current(generation)) throw StateError('Session changed');
      accept(result);
      _notify();
      return result;
    } finally {
      if (_current(generation)) {
        _busy.remove(key);
        _drainRefresh();
      }
    }
  }

  Future<void> toggleBookmark(int id) async {
    final save = !bookmarked(id);
    await _mutate(
      'b:$id',
      (u, c) => api.bookmark(u, id, save, cancelToken: c),
      (_) {
        if (save) {
          _bookmarks.add(id);
        } else {
          _bookmarks.remove(id);
        }
      },
    );
  }

  Future<void> saveProgress(
    int templateId,
    int sectionId, {
    bool? completed,
  }) async {
    if (!(template(templateId)?.allSections.any((s) => s.id == sectionId) ??
        false)) {
      throw StateError('Unknown section');
    }
    await _mutate(
      'p:$templateId',
      (u, c) => api.saveProgress(
        u,
        templateId,
        sectionId,
        completed: completed,
        cancelToken: c,
      ),
      (p) => _progress[templateId] = p,
    );
  }

  Future<LearningSubmission> submit(int questionId, String answer) async {
    final q = question(questionId);
    if (q == null ||
        answer.trim().isEmpty ||
        (q.questionType.hasChoices &&
            !q.choiceOptions.any((c) => c.key == answer))) {
      throw StateError('Invalid answer');
    }
    return _mutate(
      'q:$questionId',
      (u, c) => api.submit(u, q, answer, cancelToken: c),
      (s) {
        _submissions[questionId] = s;
        if (_passed(q, s)) _solved.add(questionId);
      },
    );
  }

  int? categoryId(String code) =>
      categories.where((c) => c.code == code).firstOrNull?.id;
  Set<int> categoryIds(String code) {
    final root = categoryId(code);
    if (root == null) return {};
    final ids = <int>{root};
    var changed = true;
    while (changed) {
      changed = false;
      for (final c in categories) {
        if (ids.contains(c.parentId) && ids.add(c.id)) changed = true;
      }
    }
    return ids;
  }

  bool isGrammar(LearningTemplate item) =>
      categoryIds('GRAMMAR').contains(item.categoryId);
  String languageName(int? id) =>
      languages.where((l) => l.id == id).firstOrNull?.name ?? '언어 공통';
  String categoryName(int id) =>
      categories.where((c) => c.id == id).firstOrNull?.name ?? '학습';
  String templateListLocation(LearningTemplate t) {
    if (!isGrammar(t)) return '/practical/${t.categoryId}/templates';
    final language = languages.where((l) => l.id == t.languageId).firstOrNull;
    return language == null
        ? '/grammar/common/chapters'
        : '/grammar/${Uri.encodeComponent(language.code.toLowerCase())}/chapters';
  }

  String templateLocation(LearningTemplate t) =>
      '${templateListLocation(t)}/${t.id}';
  @override
  void dispose() {
    _disposed = true;
    _cancel.cancel('Disposed');
    super.dispose();
  }
}
