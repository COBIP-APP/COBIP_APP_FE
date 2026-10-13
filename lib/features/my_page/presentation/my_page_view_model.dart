import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../learning/data/learning_api.dart';
import '../../learning/data/learning_destination.dart';
import '../data/my_page_api.dart';

class MyPageSection<T> {
  T? _data;
  String? _error;
  bool _loading = false;
  Future<void>? _pending;
  T? get data => _data;
  String? get error => _error;
  bool get loading => _loading;
}

class MyPageViewModel extends ChangeNotifier {
  MyPageViewModel({required this.api, required this.userId});
  final MyPageApi api;
  final int userId;
  final profile = MyPageSection<MyProfile>();
  final progress = MyPageSection<List<MyLearningRecord>>();
  final bookmarks = MyPageSection<List<MyBookmark>>();
  final recent = MyPageSection<List<MyRecentResult>>();
  final _cancel = CancelToken();
  final _removing = <int>{};
  final _deletedQuestions = <int>{};
  bool _disposed = false;
  bool _recentRequested = false;
  bool _opening = false;
  bool get opening => _opening;
  bool get disposed => _disposed;
  bool removing(int id) => _removing.contains(id);
  bool get refreshing =>
      profile.loading ||
      progress.loading ||
      bookmarks.loading ||
      recent.loading;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String message(Object error) => error is LearningApiException
      ? error.message
      : '요청을 완료하지 못했어요. 잠시 후 다시 시도해 주세요.';

  Future<void> _load<T>(MyPageSection<T> section, Future<T> Function() fetch) {
    if (_disposed) return Future.value();
    if (section._pending != null) return section._pending!;
    section._loading = true;
    section._error = null;
    _notify();
    return section._pending = (() async {
      try {
        final data = await Future<T>.sync(fetch);
        if (!_disposed) section._data = data;
      } catch (error) {
        if (!_disposed) section._error = message(error);
      } finally {
        section._loading = false;
        section._pending = null;
        _notify();
      }
    })();
  }

  Future<void> loadProfile() =>
      _load(profile, () => api.profile(userId, _cancel));
  Future<void> loadProgress() => _load(progress, () => api.progress(_cancel));
  Future<void> loadBookmarks() => _removing.isNotEmpty
      ? Future.value()
      : _load(bookmarks, () => api.bookmarks(userId, _cancel));
  Future<void> loadRecent() {
    _recentRequested = true;
    return _load(recent, () async {
      final items = await api.recent(userId, _cancel);
      return items
          .where((item) => !_deletedQuestions.contains(item.question.id))
          .toList();
    });
  }

  void questionDeleted(int id) {
    if (_disposed) return;
    _deletedQuestions.add(id);
    if (recent.data != null) {
      recent._data = recent.data!
          .where((item) => item.question.id != id)
          .toList();
    }
    _notify();
  }

  Future<void> refresh() async {
    await Future.wait([
      loadProfile(),
      loadProgress(),
      loadBookmarks(),
      if (_recentRequested) loadRecent(),
    ]);
  }

  Future<void> removeBookmark(int templateId) async {
    if (_disposed || bookmarks.loading || !_removing.add(templateId)) return;
    _notify();
    try {
      await api.learning.bookmark(
        userId,
        templateId,
        false,
        cancelToken: _cancel,
      );
      if (_disposed) return;
      bookmarks._data = List.unmodifiable(
        bookmarks.data!.where((item) => item.templateId != templateId),
      );
    } finally {
      _removing.remove(templateId);
      _notify();
    }
  }

  Future<LearningDestination?> destination(int id, int? sectionId) async {
    if (_disposed || _opening) return null;
    _opening = true;
    _notify();
    try {
      final result = await api.destination(id, sectionId, _cancel);
      return _disposed ? null : result;
    } finally {
      _opening = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _cancel.cancel('My page session closed');
    super.dispose();
  }
}
