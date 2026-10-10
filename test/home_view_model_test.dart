import 'dart:async';

import 'package:cobip_app_fe/features/home/data/home_api.dart';
import 'package:cobip_app_fe/features/home/presentation/home_view_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_support.dart';

Map<String, Object?> _template(int id) => {
  'id': id,
  'title': '학습 $id',
  'published': true,
};

Map<String, Object?> _progress(int id, String lastStudiedAt) => {
  'userId': 1,
  'templateId': id,
  'lastSectionId': null,
  'startedAt': '2026-10-01T09:00:00Z',
  'lastStudiedAt': lastStudiedAt,
  'completedAt': null,
};

HomeViewModel _viewModel(TestAuthAdapter adapter) =>
    HomeViewModel(api: HomeApi(testApi(adapter).dio), userId: 1);

void main() {
  test('빈 공개 목록은 진도를 요청하지 않고 빈 상태가 된다', () async {
    final adapter = TestAuthAdapter();
    final viewModel = _viewModel(adapter);
    addTearDown(viewModel.dispose);
    await viewModel.load();
    expect(viewModel.state, HomeContentState.empty);
    expect(viewModel.templates, isEmpty);
    expect(viewModel.latestTemplate, isNull);
    expect(viewModel.latestProgress, isNull);
    expect(adapter.requests, hasLength(1));
  });

  test('진도 404는 목록을 유지하고 마지막 학습 없이 표시한다', () async {
    final adapter = TestAuthAdapter(
      handle: (options) async => options.path == '/api/templates'
          ? jsonResponse([_template(42)], 200)
          : jsonResponse({'status': 404}, 404),
    );
    final viewModel = _viewModel(adapter);
    addTearDown(viewModel.dispose);
    await viewModel.load();
    expect(viewModel.state, HomeContentState.loaded);
    expect(viewModel.templates.single.id, 42);
    expect(viewModel.latestTemplate, isNull);
    expect(viewModel.latestProgress, isNull);
    expect(viewModel.errorMessage, isNull);
  });

  test('응답 순서가 아니라 마지막 학습 시간으로 최신 항목을 선택한다', () async {
    final older = Completer<ResponseBody>();
    final newer = Completer<ResponseBody>();
    final adapter = TestAuthAdapter(
      handle: (options) async {
        if (options.path == '/api/templates') {
          return jsonResponse([_template(42), _template(43)], 200);
        }
        return options.path.endsWith('/42') ? older.future : newer.future;
      },
    );
    final viewModel = _viewModel(adapter);
    addTearDown(viewModel.dispose);
    final loading = viewModel.load();
    newer.complete(jsonResponse(_progress(43, '2026-10-10T10:00:00Z'), 200));
    older.complete(jsonResponse(_progress(42, '2026-10-02T10:00:00Z'), 200));
    await loading;
    expect(viewModel.state, HomeContentState.loaded);
    expect(viewModel.latestTemplate?.id, 43);
    expect(viewModel.latestProgress?.templateId, 43);
    expect(viewModel.templates.map((template) => template.id), [42, 43]);
  });

  test('일부 진도 요청 실패를 미시작으로 숨기지 않고 재시도한다', () async {
    var fails = true;
    final adapter = TestAuthAdapter(
      handle: (options) async {
        if (options.path == '/api/templates') {
          return jsonResponse([_template(42), _template(43)], 200);
        }
        if (fails && options.path.endsWith('/43')) {
          return jsonResponse({'status': 503}, 503);
        }
        return jsonResponse(
          _progress(42, '2026-10-02T10:00:00Z')
            ..['templateId'] = int.parse(options.path.split('/').last),
          200,
        );
      },
    );
    final viewModel = _viewModel(adapter);
    addTearDown(viewModel.dispose);
    await viewModel.load();
    expect(viewModel.state, HomeContentState.error);
    expect(viewModel.errorMessage, isNotEmpty);
    expect(viewModel.latestTemplate, isNull);
    fails = false;
    await viewModel.load();
    expect(viewModel.state, HomeContentState.loaded);
    expect(viewModel.errorMessage, isNull);
    expect(viewModel.templates, hasLength(2));
    expect(
      adapter.requests.where((request) => request.path == '/api/templates'),
      hasLength(2),
    );
  });

  test('목록 서버 오류 후 재시도 성공으로 오류 상태를 해제한다', () async {
    final adapter = TestAuthAdapter(
      handle: (_) async => jsonResponse({'status': 503}, 503),
    );
    final viewModel = _viewModel(adapter);
    addTearDown(viewModel.dispose);
    await viewModel.load();
    expect(viewModel.state, HomeContentState.error);
    adapter.handle = (_) async => jsonResponse([], 200);
    await viewModel.load();
    expect(viewModel.state, HomeContentState.empty);
    expect(viewModel.errorMessage, isNull);
  });

  test('로딩 중 반복 호출은 목록 요청을 중복하지 않는다', () async {
    final response = Completer<ResponseBody>();
    final adapter = TestAuthAdapter(handle: (_) => response.future);
    final viewModel = _viewModel(adapter);
    addTearDown(viewModel.dispose);
    final first = viewModel.load();
    final second = viewModel.load();
    expect(viewModel.state, HomeContentState.loading);
    response.complete(jsonResponse([], 200));
    await Future.wait([first, second]);
    expect(adapter.requests, hasLength(1));
    expect(viewModel.state, HomeContentState.empty);
  });

  test('dispose 이후 늦은 응답은 상태 알림을 보내지 않는다', () async {
    final response = Completer<ResponseBody>();
    final adapter = TestAuthAdapter(handle: (_) => response.future);
    final viewModel = _viewModel(adapter);
    var notifications = 0;
    viewModel.addListener(() => notifications++);
    final loading = viewModel.load();
    final beforeDispose = notifications;
    viewModel.dispose();
    response.complete(jsonResponse([], 200));
    await loading;
    expect(notifications, beforeDispose);
    expect(viewModel.templates, isEmpty);
  });

  test('템플릿 다섯 개의 진도를 최대 네 개씩 조회한다', () async {
    final responses = List.generate(5, (_) => Completer<ResponseBody>());
    final firstBatch = Completer<void>();
    var active = 0;
    var maximumActive = 0;
    var progressRequests = 0;
    final adapter = TestAuthAdapter(
      handle: (options) async {
        if (options.path == '/api/templates') {
          return jsonResponse(
            List.generate(5, (index) => _template(index + 1)),
            200,
          );
        }
        final id = int.parse(options.path.split('/').last);
        active++;
        progressRequests++;
        if (active > maximumActive) maximumActive = active;
        if (progressRequests == 4) firstBatch.complete();
        try {
          return await responses[id - 1].future;
        } finally {
          active--;
        }
      },
    );
    final viewModel = _viewModel(adapter);
    addTearDown(viewModel.dispose);
    final loading = viewModel.load();
    await firstBatch.future;
    expect(progressRequests, 4);
    expect(active, 4);
    responses.last.complete(jsonResponse({'status': 404}, 404));
    for (final response in responses.take(4)) {
      response.complete(jsonResponse({'status': 404}, 404));
    }
    await loading;
    expect(progressRequests, 5);
    expect(maximumActive, 4);
    expect(active, 0);
    expect(viewModel.state, HomeContentState.loaded);
    expect(viewModel.templates, hasLength(5));
  });
}
