import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:cobip_app_fe/features/problems/data/ai_api.dart';
import 'package:cobip_app_fe/features/problems/data/ai_models.dart';
import 'package:cobip_app_fe/features/problems/presentation/ai_quiz_view_model.dart';
import 'package:cobip_app_fe/features/chat/presentation/chat_view_model.dart';

import 'auth_test_support.dart';
import 'ai_test_support.dart';

void main() {
  test('운영 AI 전용 클라이언트는 BE 주소·토큰·인터셉터를 공유하지 않는다', () async {
    final backend = Dio(
      BaseOptions(
        baseUrl: 'https://be.test',
        headers: {'Authorization': 'Bearer private-be-token'},
      ),
    );
    var backendRequests = 0;
    backend.interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) {
          backendRequests++;
          h.next(r);
        },
      ),
    );
    final api = AiApi.fromEnvironment(backend: backend);
    addTearDown(api.dispose);
    final server = AiTestServer();
    api.dio.httpClientAdapter = server;
    await api.chat('연결 확인');
    final request = server.calls('/ai/chat').single;
    expect(request.uri.toString(), 'https://ai.cobip.tech/ai/chat');
    expect(
      request.headers.keys.any((k) => k.toLowerCase() == 'authorization'),
      isFalse,
    );
    expect(request.extra['authRequired'], isFalse);
    expect(backendRequests, 0);
    expect(backend.options.baseUrl, 'https://be.test');
    expect(request.followRedirects, isFalse);
  });
  test('기존 BE 인증으로 혼합 유형 생성, 번호 제출, 6필드 채점과 해설을 사용한다', () async {
    final server = AiTestServer();
    final auth = await testAuth(authenticated: true, adapter: server);
    addTearDown(auth.dispose);
    final api = AiApi(auth.api.dio, viaBackend: true);
    final batch = await api.generate(
      category: 'Infrastructure',
      domain: 'AWS',
      userId: '1',
      difficulty: '중급',
      types: [
        AiQuizType.multipleChoice,
        AiQuizType.blank,
        AiQuizType.descriptive,
      ],
      countPerType: 1,
    );
    final request = server.calls('/ai/quiz/generate').single;
    expect(request.uri.host, 'api.test');
    expect(request.headers['Authorization'], 'Bearer test-access-1');
    expect(request.data, {
      'category': 'Infrastructure',
      'domain': 'AWS',
      'user_id': '1',
      'difficulty': '중급',
      'quiz_types': ['MULTIPLE_CHOICE', 'BLANK', 'DESCRIPTIVE'],
      'count_per_type': 1,
    });
    expect(request.receiveTimeout, const Duration(minutes: 5));
    final grade = await api.grade(
      batch: batch,
      quiz: batch.quizzes.first,
      answer: '2',
    );
    expect(server.calls('/ai/quiz/grade').single.data['userAnswer'], '2');
    expect(
      server.calls('/ai/quiz/grade').single.data['question']['options'][1],
      '2. TreeMap',
    );
    expect(grade.isCorrect, isTrue);
    expect(grade.score, 100);
    expect(grade.feedback, '채점 피드백');
    expect(grade.correctAnswer, '2');
    expect(grade.explanation, '채점 후 해설');
    expect(grade.relatedSection, isNull);
    final explanation = await api.explain(
      question: batch.quizzes.first.question,
      answer: '2',
      correctAnswer: grade.correctAnswer,
    );
    expect(explanation.summary, ['핵심 요약']);
    expect(explanation.detailedExplanation, '상세 해설');
  });

  for (final type in AiQuizType.values) {
    test('${type.code} 생성 객체와 gradingKeywords를 채점에 보존한다', () async {
      final server = AiTestServer();
      final api = AiApi(testApi(server).dio);
      final batch = AiQuizBatch.fromJson(generatedBatch());
      final quiz = AiQuiz.fromJson(generatedQuiz(9, type.code));
      await api.grade(
        batch: batch,
        quiz: quiz,
        answer: type.hasOptions ? '2' : '사용자 답안',
      );
      final body = server.calls('/ai/quiz/grade').single.data as Map;
      expect(body['question']['type'], type.code);
      expect(body['question']['answer'], quiz.answer);
      expect(body['question']['gradingKeywords'], ['개념']);
      expect(body['userAnswer'], type.hasOptions ? '2' : '사용자 답안');
    });
  }

  test('Java snake_case 결과를 읽고 문제와 코드를 전송한다', () async {
    final server = AiTestServer();
    final result = await AiApi(testApi(server).dio)
        .gradeJava(question: '문제', code: 'class Main {}');
    expect(server.calls('/ai/java/grade').single.data, {
      'question': '문제',
      'code': 'class Main {}',
    });
    expect(result.isCorrect, isTrue);
    expect(result.score, 90);
    expect(result.feedback, 'Java 피드백');
    expect(result.formattedCode, 'class Main {}');
  });

  for (final status in [404, 422, 500]) {
    test('$status 오류의 JSON/text 본문을 노출하지 않고 자동 재시도하지 않는다', () async {
      final server = AiTestServer()
        ..aiHandler = (_) async => status == 500
            ? ResponseBody.fromString('Internal Server Error secret', 500)
            : jsonResponse({
                'detail': [
                  {'secret': 'hidden'},
                ],
              }, status);
      await expectLater(
        AiApi(testApi(server).dio).chat('질문'),
        throwsA(
          isA<AiApiException>().having(
            (e) => e.message.contains('secret'),
            '민감한 원문 미노출',
            isFalse,
          ),
        ),
      );
      expect(server.calls('/ai/chat'), hasLength(1));
    });
  }
  test('타임아웃 후 자동으로 AI POST를 반복하지 않는다', () async {
    final server = AiTestServer()
      ..aiHandler = (r) async => throw DioException(
        requestOptions: r,
        type: DioExceptionType.receiveTimeout,
      );
    await expectLater(
      AiApi(testApi(server).dio).chat('질문'),
      throwsA(
        isA<AiApiException>().having(
          (e) => e.message,
          '시간 초과',
          contains('시간이 초과'),
        ),
      ),
    );
    expect(server.calls('/ai/chat'), hasLength(1));
  });
  test('401 토큰 갱신 후에도 AI 요청은 자동 재전송하지 않는다', () async {
    final server = AiTestServer()
      ..aiHandler = (_) async => jsonResponse({}, 401);
    // LearningServer does not implement refresh; provide the normal auth contract.
    server.handle = (r) async => r.path == '/api/auth/refresh'
        ? jsonResponse(testTokens(2), 200)
        : server.respondAll(r);
    final auth = await testAuth(authenticated: true, adapter: server);
    addTearDown(auth.dispose);
    await expectLater(
      AiApi(auth.api.dio, viaBackend: true).chat('질문'),
      throwsA(isA<AiApiException>()),
    );
    expect(server.calls('/ai/chat'), hasLength(1));
    expect(server.calls('/api/auth/refresh'), hasLength(1));
  });
  test('생성/채점 중복 방지, 실패 답안 유지, 재시도와 dispose를 처리한다', () async {
    final server = AiTestServer();
    final generated = Completer<ResponseBody>();
    server.aiHandler = (_) => generated.future;
    final vm = AiQuizViewModel(AiApi(testApi(server).dio));
    Future<void> generate() => vm.generate(
      category: 'Java',
      difficulty: '중급',
      types: [AiQuizType.multipleChoice],
      countPerType: 1,
      domain: '',
    );
    final first = generate();
    await generate();
    generated.complete(aiResponse(generatedBatch()));
    await first;
    expect(server.calls('/ai/quiz/generate'), hasLength(1));
    vm.answerChanged('2');
    final graded = Completer<ResponseBody>();
    server.aiHandler = (_) => graded.future;
    final submit = vm.submit();
    await vm.submit();
    vm.select(1);
    vm.answerChanged('1');
    expect(vm.index, 0);
    expect(vm.answer, '2');
    graded.complete(jsonResponse({}, 500));
    await submit;
    expect(vm.error, isNotNull);
    expect(vm.answer, '2');
    expect(vm.result, isNull);
    server.aiHandler = (_) async => aiResponse(quizGrade());
    await vm.submit();
    expect(vm.result!.isCorrect, isTrue);
    expect(server.calls('/ai/quiz/grade'), hasLength(2));
    vm.retry();
    final late = Completer<ResponseBody>();
    server.aiHandler = (_) => late.future;
    final pending = vm.submit();
    vm.dispose();
    late.complete(aiResponse(quizGrade()));
    await pending;
  });
  test('챗봇 fallback은 성공 답변으로 표시하지 않고 수동 재시도한다', () async {
    final server = AiTestServer()
      ..aiHandler = (_) async => aiResponse({
        'answer': '기본 안내',
        'source': 'fallback',
        'ragUsed': false,
        'references': [],
        'intent': null,
      });
    final vm = ChatViewModel(api: AiApi(testApi(server).dio));
    addTearDown(vm.dispose);
    await vm.send('질문');
    expect(vm.messages, hasLength(2));
    expect(vm.error, contains('생성하지 못했어요'));
    server.aiHandler = null;
    await vm.retry();
    expect(vm.messages, hasLength(3));
    expect(vm.messages.last.text, '서버 챗봇 답변');
    expect(server.calls('/ai/chat').first.data, {
      'message': '질문',
      'context': null,
      'useRag': null,
    });
  });
  test('챗봇 중복 요청과 사용자 변경 후 늦은 응답을 막는다', () async {
    final server = AiTestServer();
    final delayed = Completer<ResponseBody>();
    final started = Completer<void>();
    server.aiHandler = (_) {
      started.complete();
      return delayed.future;
    };
    final vm = ChatViewModel(api: AiApi(testApi(server).dio))..bindUser(1);
    addTearDown(vm.dispose);
    final pending = vm.send('첫 질문');
    await vm.send('중복 질문');
    await started.future;
    expect(server.calls('/ai/chat'), hasLength(1));
    vm.bindUser(2);
    delayed.complete(
      aiResponse({
        'answer': '이전 사용자 응답',
        'source': 'ollama',
        'ragUsed': false,
        'references': [],
        'intent': null,
      }),
    );
    await pending;
    expect(vm.messages, hasLength(1));
    expect(vm.error, isNull);
  });
}
