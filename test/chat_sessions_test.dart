import 'dart:async';

import 'package:cobip_app_fe/app/cobip_app.dart';
import 'package:cobip_app_fe/app/router/app_router.dart';
import 'package:cobip_app_fe/features/chat/presentation/chat_panel.dart';
import 'package:cobip_app_fe/features/chat/presentation/chat_sessions.dart';
import 'package:cobip_app_fe/features/problems/data/ai_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'ai_test_support.dart';
import 'auth_test_support.dart';

ResponseBody reply(String text) => aiResponse({
  'answer': text,
  'source': 'ollama',
  'ragUsed': false,
  'references': [],
  'intent': 'TECHNICAL',
});

void main() {
  test('카드별로 요청·로딩·답변·초안을 격리하고 다시 열면 유지한다', () async {
    final server = AiTestServer();
    final waiting = Completer<ResponseBody>();
    server.aiHandler = (r) => r.data['message'] == '조건문 질문'
        ? waiting.future
        : Future.value(reply('반복문 답변'));
    final sessions = ChatSessions(api: AiApi(testApi(server).dio))..bindUser(1);
    addTearDown(sessions.dispose);
    final first = sessions.conversation(ChatSessions.templateKey(121));
    final second = sessions.conversation(ChatSessions.templateKey(122));
    final main = sessions.conversation(ChatSessions.mainKey);
    final pending = first.send('조건문 질문');
    await first.send('중복 질문');
    expect(first.busy, isTrue);
    expect(second.busy, isFalse);
    expect(main.messages, hasLength(1));
    await second.send('반복문 질문');
    second.draft = '반복문 초안';
    waiting.complete(reply('조건문 답변'));
    await pending;
    expect(first.messages.last.text, '조건문 답변');
    expect(second.messages.last.text, '반복문 답변');
    expect(first.messages.any((m) => m.text == '반복문 질문'), isFalse);
    expect(sessions.conversation(ChatSessions.templateKey(122)), same(second));
    expect(second.draft, '반복문 초안');
    expect(first.draft, isEmpty);
    expect(server.calls('/ai/chat'), hasLength(2));
  });

  test('실패와 재시도도 해당 카드에만 적용한다', () async {
    final server = AiTestServer()
      ..aiHandler = (_) async => jsonResponse({}, 500);
    final sessions = ChatSessions(api: AiApi(testApi(server).dio))..bindUser(1);
    addTearDown(sessions.dispose);
    final first = sessions.conversation(ChatSessions.templateKey(121));
    final other = sessions.conversation(ChatSessions.templateKey(201));
    await first.send('실패한 질문');
    expect(first.error, isNotNull);
    expect(other.error, isNull);
    server.aiHandler = (_) async => reply('실무 답변');
    await other.send('실무 질문');
    server.aiHandler = (_) async => reply('재시도 답변');
    await first.retry();
    expect(server.calls('/ai/chat').last.data['message'], '실패한 질문');
    expect(first.messages.where((m) => m.isUser), hasLength(1));
    expect(first.messages.last.text, '재시도 답변');
    expect(other.messages.last.text, '실무 답변');
  });

  test('로그아웃·계정 변경은 모든 대화와 초안을 비우고 늦은 답변을 무시한다', () async {
    final server = AiTestServer();
    final sessions = ChatSessions(api: AiApi(testApi(server).dio))..bindUser(1);
    addTearDown(sessions.dispose);
    final main = sessions.conversation(ChatSessions.mainKey);
    final card = sessions.conversation(ChatSessions.templateKey(121));
    await main.send('메인 질문');
    main.draft = '메인 초안';
    final waiting = Completer<ResponseBody>();
    final started = Completer<void>();
    server.aiHandler = (_) {
      started.complete();
      return waiting.future;
    };
    final pending = card.send('응답 대기 중');
    await started.future;
    sessions.bindUser(null);
    sessions.bindUser(2);
    waiting.complete(reply('이전 계정 답변'));
    await pending;
    for (final chat in [main, card]) {
      expect(chat.messages, hasLength(1));
      expect(chat.draft, isEmpty);
      expect(chat.error, isNull);
      expect(chat.busy, isFalse);
    }
    server.aiHandler = (_) async => reply('새 계정 답변');
    await card.send('새 질문');
    sessions.bindUser(2); // Token refresh for the same user preserves messages.
    expect(card.messages.last.text, '새 계정 답변');
    sessions.bindUser(null);
    sessions.bindUser(2);
    expect(card.messages, hasLength(1));
    final restarted = ChatSessions(api: sessions.api)..bindUser(2);
    addTearDown(restarted.dispose);
    expect(
      restarted.conversation(ChatSessions.templateKey(121)).messages,
      hasLength(1),
    );
  });

  testWidgets('문법 카드·목차·실무·메인 이동 시 대화와 작성 중 입력을 분리한다', (tester) async {
    final server = AiTestServer()
      ..aiHandler = (r) async => reply('답변: ${r.data['message']}');
    final auth = await tester.runAsync(
      () => testAuth(authenticated: true, adapter: server),
    );
    addTearDown(auth!.dispose);
    final router = createAppRouter(
      initialLocation: '/grammar/python/chapters/121',
    );
    addTearDown(router.dispose);
    await tester.pumpWithAuth(CobipApp(router: router), auth: auth);
    await tester.pumpAndSettle();

    Future<void> open(String route) async {
      router.go(route);
      await tester.pumpAndSettle();
      if (route != '/chat') {
        await tester.tap(find.byTooltip('COBIA 챗봇'));
        await tester.pumpAndSettle();
      }
    }

    Future<void> close() async {
      tester.testTextInput.hide();
      await tester.tap(find.byTooltip('챗봇 닫기'));
      await tester.pumpAndSettle();
    }

    Future<void> send(String text) async {
      await tester.enterText(find.byKey(const ValueKey('chat-input')), text);
      await tester.pump();
      await tester.tap(find.byTooltip('메시지 보내기'));
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
    }

    String input() => tester
        .widget<TextField>(find.byKey(const ValueKey('chat-input')))
        .controller!
        .text;

    await tester.tap(find.byTooltip('COBIA 챗봇'));
    await tester.pumpAndSettle();
    await send('파이썬 조건문 질문');
    await tester.enterText(find.byKey(const ValueKey('chat-input')), '조건문 초안');
    await close();
    await open('/grammar/python/chapters/122');
    expect(input(), isEmpty);
    expect(find.text('답변: 파이썬 조건문 질문'), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('chat-input')), '반복문 초안');
    await close();
    // A different section of the same card shares its conversation.
    await open('/grammar/python/chapters/121?section=12102');
    expect(input(), '조건문 초안');
    expect(find.text('답변: 파이썬 조건문 질문'), findsOneWidget);
    await close();
    // Same title in a different language must not share a conversation.
    await open('/grammar/java/chapters/111');
    expect(input(), isEmpty);
    expect(find.text('답변: 파이썬 조건문 질문'), findsNothing);
    await close();
    await open('/practical/4/templates/201');
    await send('실무 캐시 질문');
    await close();
    await open('/chat');
    expect(find.text('답변: 실무 캐시 질문'), findsNothing);
    expect(find.text('답변: 파이썬 조건문 질문'), findsNothing);
    await send('메인 질문');
    await open('/practical/4/templates/201');
    expect(find.text('답변: 실무 캐시 질문'), findsOneWidget);
    expect(find.text('답변: 메인 질문'), findsNothing);
    await close();
    await open('/grammar/python/chapters/122');
    expect(input(), '반복문 초안');
    await close();
    await open('/chat');
    expect(find.text('답변: 메인 질문'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('챗봇을 닫은 상태에서 로그아웃하고 같은 계정으로 로그인해도 초기화한다', (tester) async {
    final auth = await tester.runAsync(() => testAuth(authenticated: true));
    addTearDown(auth!.dispose);
    final router = createAppRouter(initialLocation: '/chat');
    addTearDown(router.dispose);
    await tester.pumpWithAuth(CobipApp(router: router), auth: auth);
    await tester.pumpAndSettle();
    final sessions = tester
        .element(find.byType(ChatPanel))
        .read<ChatSessions>();
    sessions.conversation(ChatSessions.mainKey).draft = '메인 초안';
    sessions.conversation(ChatSessions.templateKey(121)).draft = '카드 초안';
    router.go('/problems');
    await tester.pumpAndSettle();
    expect(find.byType(ChatPanel), findsNothing);
    await tester.runAsync(auth.clearSession);
    await tester.pumpAndSettle();
    expect(sessions.conversation(ChatSessions.mainKey).draft, isEmpty);
    expect(sessions.conversation(ChatSessions.templateKey(121)).draft, isEmpty);
    await tester.runAsync(() => auth.login('member@example.com', 'password'));
    await tester.pumpAndSettle();
    router.go('/chat');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('chat-input')))
          .controller!
          .text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('열린 챗봇에서도 계정 변경 시 입력 컨트롤러를 초기화한다', (tester) async {
    final router = createAppRouter(initialLocation: '/chat');
    addTearDown(router.dispose);
    await tester.pumpLearningWidget(CobipApp(router: router));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('chat-input')),
      '이전 사용자 초안',
    );
    final sessions = tester
        .element(find.byType(ChatPanel))
        .read<ChatSessions>();
    sessions.bindUser(2);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('chat-input')))
          .controller!
          .text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });
}
