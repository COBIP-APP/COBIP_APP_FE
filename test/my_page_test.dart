import 'dart:async';

import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/features/learning/data/learning_api.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_store.dart';
import 'package:cobip_app_fe/features/my_page/data/my_page_api.dart';
import 'package:cobip_app_fe/features/my_page/presentation/my_page_view_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_support.dart';
import 'learning_test_support.dart';

class MyPageServer extends LearningServer {
  bool empty = false;
  int profileOwner = 1;
  int bookmarkOwner = 1;
  @override
  Future<ResponseBody> respond(RequestOptions r) async {
    if (failure != null && (failurePath == null || failurePath == r.path)) {
      return jsonResponse({}, failure!);
    }
    if (r.path == '/api/users/me') {
      return jsonResponse({
        ...testUser,
        'userId': profileOwner,
        'createdAt': '2026-10-01T00:00:00Z',
      }, 200);
    }
    if (r.path == '/api/users/me/progress') {
      return jsonResponse([
        if (!empty)
          {
            'templateId': 31,
            'title': '서버 조건문',
            'categoryCode': 'GRAMMAR',
            'categoryName': '문법',
            'languageCode': null,
            'languageName': null,
            'lastSectionId': null,
            'lastSectionTitle': null,
            'startedAt': stamp,
            'lastStudiedAt': stamp,
            'completedAt': null,
          },
      ], 200);
    }
    if (r.path == '/api/users/1/bookmarks') {
      return jsonResponse([
        if (bookmarked)
          {
            'userId': bookmarkOwner,
            'templateId': 31,
            'title': '저장한 조건문',
            'summary': null,
            'difficulty': 'NORMAL',
            'createdAt': stamp,
          },
      ], 200);
    }
    if (empty && r.path == '/api/questions') return jsonResponse([], 200);
    return super.respond(r);
  }
}

Future<void> settleNetwork(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 10));
  }
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    220,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  late MyPageServer server;
  late MyPageApi api;
  late MyPageViewModel vm;
  setUp(() {
    server = MyPageServer();
    api = MyPageApi(testApi(server).dio);
    vm = MyPageViewModel(api: api, userId: 1);
  });
  tearDown(() {
    if (!vm.disposed) vm.dispose();
  });

  test('기존 응답의 가입일·목차 null·북마크 날짜를 보존하고 최근 결과는 지연 조회', () async {
    server.bookmarked = true;
    await vm.refresh();
    expect(vm.profile.data!.createdAt, DateTime.utc(2026, 10, 1));
    expect(vm.progress.data!.single.title, '서버 조건문');
    expect(vm.progress.data!.single.lastSectionId, isNull);
    expect(vm.bookmarks.data!.single.createdAt, DateTime.parse(stamp));
    expect(vm.bookmarks.data!.single.summary, isNull);
    expect(server.requests.any((r) => r.path == '/api/questions'), isFalse);
    expect(
      server.requests.every((r) => r.extra['authRequired'] == true),
      isTrue,
    );
  });

  test('한 영역의 실패는 다른 영역을 막지 않고 재시도할 수 있다', () async {
    server.failure = 500;
    server.failurePath = '/api/users/me/progress';
    await vm.refresh();
    expect(vm.profile.data, isNotNull);
    expect(vm.bookmarks.data, isEmpty);
    expect(vm.progress.data, isNull);
    expect(vm.progress.error, isNotNull);
    server.failure = null;
    await vm.loadProgress();
    expect(vm.progress.error, isNull);
    expect(vm.progress.data, hasLength(1));
  });

  test('다른 사용자의 프로필·북마크 응답을 거부한다', () async {
    server.profileOwner = 2;
    server.bookmarkOwner = 2;
    server.bookmarked = true;
    await vm.refresh();
    expect(vm.profile.data, isNull);
    expect(vm.profile.error, isNotNull);
    expect(vm.bookmarks.data, isNull);
    expect(vm.bookmarks.error, isNotNull);
  });

  test('북마크 해제 실패는 목록을 유지하고 성공 이후에만 제거한다', () async {
    server.bookmarked = true;
    await vm.loadBookmarks();
    server.failure = 500;
    server.failurePath = '/api/users/1/bookmarks/templates/31';
    await expectLater(
      vm.removeBookmark(31),
      throwsA(isA<LearningApiException>()),
    );
    expect(vm.bookmarks.data, hasLength(1));
    expect(vm.removing(31), isFalse);
    server.failure = null;
    await vm.removeBookmark(31);
    expect(vm.bookmarks.data, isEmpty);
    expect(server.bookmarked, isFalse);
  });

  test('최신 제출 404만 미제출이며 일부 500을 빈 결과로 바꾸지 않는다', () async {
    await vm.loadRecent();
    expect(vm.recent.data, isEmpty);
    server.failure = 500;
    server.failurePath = '/api/questions/42/submissions/latest';
    await vm.loadRecent();
    expect(vm.recent.error, isNotNull);
  });

  test('채점 대기와 최신 제출 시각·ID 순서를 유지한다', () async {
    for (final id in [41, 42]) {
      server.saved[id] = {
        'id': id,
        'userId': 1,
        'questionId': id,
        'gradingStatus': 'PENDING',
        'score': null,
        'submittedAt': stamp,
      };
    }
    await vm.loadRecent();
    expect(vm.recent.data!.map((r) => r.question.id), [42, 41]);
    expect(vm.recent.data!.every((r) => r.submission.pending), isTrue);
  });

  test('화면·계정이 사라진 후 도착한 응답은 표시하지 않는다', () async {
    final gate = Completer<ResponseBody>();
    server.handle = (r) =>
        r.path == '/api/users/me' ? gate.future : server.respond(r);
    var notifications = 0;
    vm.addListener(() => notifications++);
    final pending = vm.loadProfile();
    await Future<void>.delayed(Duration.zero);
    vm.dispose();
    final count = notifications;
    gate.complete(jsonResponse({...testUser, 'createdAt': stamp}, 200));
    await pending;
    expect(vm.profile.data, isNull);
    expect(notifications, count);
  });

  test('서버 ID와 실제 목차로 이동하고 사라진 목차는 거부한다', () async {
    final target = await vm.destination(31, 311);
    expect(target!.grammar, isTrue);
    expect(target.language, 'java');
    expect(target.sectionId, 311);
    await expectLater(
      vm.destination(31, 999),
      throwsA(isA<LearningApiException>()),
    );
    expect(vm.opening, isFalse);
  });

  test('공용 저장소 조회 중 외부 변경 시 오래된 응답 뒤 다시 갱신한다', () async {
    server.bookmarked = true;
    final store = LearningStore(api: api.learning)..bindUser(1);
    addTearDown(store.dispose);
    await store.load();
    expect(store.bookmarked(31), isTrue);
    final gate = Completer<ResponseBody>();
    final entered = Completer<void>();
    var waiting = true;
    server.handle = (r) {
      if (r.path == '/api/users/1/bookmarks' && waiting) {
        waiting = false;
        entered.complete();
        return gate.future;
      }
      return server.respond(r);
    };
    final oldLoad = store.load();
    await entered.future;
    server.bookmarked = false;
    store.requestRefresh();
    final refreshed = Completer<void>();
    store.addListener(() {
      if (store.state == PreviewLoadState.ready &&
          !store.bookmarked(31) &&
          !refreshed.isCompleted) {
        refreshed.complete();
      }
    });
    gate.complete(
      jsonResponse([
        {'userId': 1, 'templateId': 31},
      ], 200),
    );
    await oldLoad;
    await refreshed.future.timeout(const Duration(seconds: 3));
    expect(store.bookmarked(31), isFalse);
  });

  testWidgets('API 프로필·빈 목록·계정 관리와 로그아웃을 표시한다', (tester) async {
    server.empty = true;
    final auth = (await tester.runAsync(
      () => testAuth(authenticated: true, adapter: server),
    ))!;
    addTearDown(auth.dispose);
    final router = createAppRouter(initialLocation: '/my-page');
    addTearDown(router.dispose);
    await tester.pumpWithAuth(CobipApp(router: router), auth: auth);
    await settleNetwork(tester);
    expect(find.text('테스트학습자'), findsOneWidget);
    expect(find.text('2026.10.01 가입'), findsOneWidget);
    expect(find.text('1시간 7분'), findsNothing);
    await reveal(tester, find.text('아직 시작한 학습이 없어요.'));
    expect(find.widgetWithText(ChoiceChip, '계정 관리'), findsNothing);
    await tester.scrollUntilVisible(
      find.byTooltip('계정 관리'),
      -220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('계정 관리'));
    await settleNetwork(tester);
    expect(find.byTooltip('마이페이지로 돌아가기'), findsOneWidget);
    await reveal(tester, find.text('닉네임: 테스트학습자'));
    expect(find.text('가입일: 2026.10.01'), findsOneWidget);
    await tester.tap(find.byTooltip('마이페이지로 돌아가기'));
    await settleNetwork(tester);
    expect(router.routeInformationProvider.value.uri.path, '/my-page');
    await reveal(tester, find.byTooltip('계정 관리'));
    await tester.tap(find.byTooltip('계정 관리'));
    await settleNetwork(tester);
    await reveal(tester, find.text('로그아웃'));
    await tester.tap(find.text('로그아웃'));
    await settleNetwork(tester);
    expect(auth.user, isNull);
    expect(router.routeInformationProvider.value.uri.path, '/login');
  });

  testWidgets('320px·큰 글씨에서 긴 서버 데이터와 최근 결과를 표시한다', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final auth = (await tester.runAsync(
      () => testAuth(authenticated: true, adapter: server),
    ))!;
    addTearDown(auth.dispose);
    final router = createAppRouter(initialLocation: '/my-page');
    addTearDown(router.dispose);
    await tester.pumpWithAuth(CobipApp(router: router), auth: auth);
    await settleNetwork(tester);
    await reveal(tester, find.text('이어서 학습'));
    expect(tester.takeException(), isNull);
    await reveal(tester, find.widgetWithText(ChoiceChip, '최근 결과'));
    await tester.tap(find.widgetWithText(ChoiceChip, '최근 결과'));
    await settleNetwork(tester);
    await reveal(tester, find.text('조회 가능한 최근 제출 결과가 없어요.'));
    expect(tester.takeException(), isNull);
  });
}
