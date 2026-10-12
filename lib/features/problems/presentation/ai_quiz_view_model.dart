import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/ai_api.dart';
import '../data/ai_models.dart';
import '../../learning/data/learning_api.dart';
import '../../learning/data/learning_models.dart';
import '../../learning/presentation/learning_store.dart';

/// Practice stays page-scoped; only explicit saves persist a question in BE.
class AiQuizViewModel extends ChangeNotifier {
  AiQuizViewModel(this.api, {this.userId, this.learningStore});
  final AiApi api;
  final String? userId;
  final LearningStore? learningStore;
  final _saved = <int, LearningQuestion>{};
  final _requestIds = <int, String>{};
  LearningQuestion? get savedQuestion => _saved[_index];
  bool saving = false;
  final _cancel = CancelToken();
  bool _disposed = false;
  bool _busy = false;
  bool get busy => _busy;
  String? _error;
  String? get error => _error;
  AiQuizBatch? _batch;
  AiQuizBatch? get batch => _batch;
  int _index = 0;
  int get index => _index;
  final _answers = <int, String>{};
  final _results = <int, AiGrade>{};
  final _explanations = <int, AiExplanation>{};
  AiExplanation? get explanation => _explanations[_index];
  String get answer => _answers[_index] ?? '';
  AiGrade? get result => _results[_index];
  AiGrade? resultAt(int index) => _results[index];

  void answerChanged(String value) {
    if (_busy || result != null) return;
    _answers[_index] = value;
    notifyListeners();
  }

  void select(int index) {
    if (_busy || index < 0 || index >= (_batch?.quizzes.length ?? 0)) return;
    _index = index;
    _error = null;
    notifyListeners();
  }

  void retry() {
    if (_busy) return;
    _results.remove(_index);
    _explanations.remove(_index);
    _error = null;
    notifyListeners();
  }

  void newBatch() {
    if (_busy) return;
    _batch = null;
    _error = null;
    _index = 0;
    _answers.clear();
    _results.clear();
    _explanations.clear();
    _saved.clear();
    _requestIds.clear();
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy || _disposed) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on AiApiException catch (e) {
      if (!_disposed) _error = e.message;
    } on LearningApiException catch (e) {
      if (!_disposed) _error = e.message;
    } catch (_) {
      if (!_disposed) _error = '요청을 완료하지 못했어요. 다시 시도해 주세요.';
    } finally {
      if (!_disposed) {
        _busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> generate({
    required String category,
    required String difficulty,
    required List<AiQuizType> types,
    required int countPerType,
    required String domain,
  }) => _run(() async {
    final batch = await api.generate(
      category: category,
      difficulty: difficulty,
      types: types,
      countPerType: countPerType,
      domain: domain,
      userId: userId,
      cancelToken: _cancel,
    );
    if (_disposed) return;
    _batch = batch;
    _index = 0;
    _answers.clear();
    _results.clear();
    _explanations.clear();
    _saved.clear();
    _requestIds.clear();
  });

  Future<void> save() async {
    final store = learningStore;
    if (_busy || _disposed || _batch == null || savedQuestion != null) return;
    if (store == null || store.userId?.toString() != userId) {
      _error = '로그인 상태를 확인한 뒤 다시 저장해 주세요.';
      notifyListeners();
      return;
    }
    // Keep the same UUID on timeout/retry, even if the server already saved it.
    final requestId = _requestIds.putIfAbsent(_index, _uuid);
    saving = true;
    await _run(() async {
      final question = await store.saveGeneratedQuestion(
        clientRequestId: requestId,
        batch: _batch!,
        quiz: _batch!.quizzes[_index],
      );
      if (!_disposed) _saved[_index] = question;
    });
    saving = false;
    if (!_disposed) notifyListeners();
  }

  static String _uuid() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  Future<void> submit() async {
    if (_batch == null || result != null || answer.trim().isEmpty) return;
    await _run(() async {
      final result = await api.grade(
        batch: _batch!,
        quiz: _batch!.quizzes[_index],
        answer: answer,
        cancelToken: _cancel,
      );
      if (!_disposed) _results[_index] = result;
    });
  }

  Future<void> explain() async {
    if (result == null || explanation != null) return;
    await _run(() async {
      final value = await api.explain(
        question: _batch!.quizzes[_index].question,
        answer: answer,
        correctAnswer: result!.correctAnswer,
        cancelToken: _cancel,
      );
      if (!_disposed) _explanations[_index] = value;
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _cancel.cancel();
    super.dispose();
  }
}
