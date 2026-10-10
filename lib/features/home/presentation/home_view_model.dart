import 'package:flutter/foundation.dart';

import '../data/home_api.dart';

enum HomeContentState { loading, empty, loaded, error }

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required this.api, required this.userId});

  final HomeApi api;
  final int userId;
  HomeContentState _state = HomeContentState.loading;
  List<HomeTemplate> _templates = const [];
  HomeTemplate? _latestTemplate;
  HomeProgress? _latestProgress;
  String? _errorMessage;
  bool _isLoading = false;
  bool _disposed = false;

  HomeContentState get state => _state;
  List<HomeTemplate> get templates => _templates;
  HomeTemplate? get latestTemplate => _latestTemplate;
  HomeProgress? get latestProgress => _latestProgress;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    if (_isLoading || _disposed) return;
    _isLoading = true;
    _state = HomeContentState.loading;
    _templates = const [];
    _latestTemplate = null;
    _latestProgress = null;
    _errorMessage = null;
    notifyListeners();
    try {
      final templates = await api.fetchTemplates();
      HomeTemplate? latestTemplate;
      HomeProgress? latestProgress;
      // shortcut: 공개 목록별 N+1 조회를 최대 4개씩 실행하며, 최근 학습 집계 API 제공 시 교체합니다.
      for (var start = 0; start < templates.length; start += 4) {
        if (_disposed) return;
        final end = (start + 4).clamp(0, templates.length);
        final batch = templates.sublist(start, end);
        final progressList = await Future.wait([
          for (final template in batch) api.fetchProgress(userId, template.id),
        ]);
        for (var index = 0; index < batch.length; index++) {
          final progress = progressList[index];
          if (progress != null &&
              (latestProgress == null ||
                  progress.lastStudiedAt.isAfter(
                    latestProgress.lastStudiedAt,
                  ))) {
            latestTemplate = batch[index];
            latestProgress = progress;
          }
        }
      }
      if (_disposed) return;
      _templates = List.unmodifiable(templates);
      _latestTemplate = latestTemplate;
      _latestProgress = latestProgress;
      _state = templates.isEmpty
          ? HomeContentState.empty
          : HomeContentState.loaded;
    } on HomeApiException catch (error) {
      if (_disposed) return;
      _state = HomeContentState.error;
      _errorMessage = error.message;
    } catch (_) {
      if (_disposed) return;
      _state = HomeContentState.error;
      _errorMessage = '학습 정보를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
