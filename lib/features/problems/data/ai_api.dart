import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'ai_models.dart';

class AiApiException implements Exception {
  const AiApiException(this.message);
  final String message;
}

/// Direct AI traffic uses its own Dio, without BE credentials or interceptors.
class AiApi {
  AiApi(this.dio, {this.viaBackend = false}) : _ownsDio = false;
  AiApi._owned(this.dio) : viaBackend = false, _ownsDio = true;
  final Dio dio;
  final bool viaBackend;
  final bool _ownsDio;

  factory AiApi.fromEnvironment({required Dio backend}) {
    if (const bool.fromEnvironment('AI_USE_BE_PROXY')) {
      return AiApi(backend, viaBackend: true);
    }
    return AiApi._owned(
      Dio(
        BaseOptions(
          baseUrl: const String.fromEnvironment(
            'AI_BASE_URL',
            defaultValue: 'https://ai.cobip.tech',
          ),
          connectTimeout: const Duration(seconds: 10),
          contentType: 'application/json; charset=utf-8',
          followRedirects: false,
        ),
      ),
    );
  }

  void dispose() {
    if (_ownsDio) dio.close(force: true);
  }

  Future<T> _post<T>(
    String path,
    Map<String, Object?> body,
    T Function(Map<String, dynamic>) decode,
    CancelToken? cancelToken,
  ) async {
    final uri = Uri.tryParse(dio.options.baseUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        !['http', 'https'].contains(uri.scheme) ||
        (kReleaseMode && uri.scheme != 'https')) {
      throw const AiApiException('서버 주소가 아직 설정되지 않았어요.');
    }
    try {
      final response = await dio.post<Object?>(
        path,
        data: body,
        cancelToken: cancelToken,
        options: Options(
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(seconds: 20),
          followRedirects: false,
          extra: {'authRequired': viaBackend, 'noAuthReplay': true},
        ),
      );
      final envelope = aiObject(response.data);
      if (response.statusCode != 200 || envelope['success'] != true) {
        throw const AiApiException('AI 요청을 처리하지 못했어요. 잠시 후 다시 시도해 주세요.');
      }
      return decode(aiObject(envelope['data']));
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      throw AiApiException(switch (e.type) {
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout => 'AI 응답 시간이 초과됐어요. 잠시 후 다시 시도해 주세요.',
        DioExceptionType.connectionTimeout ||
        DioExceptionType.connectionError =>
          'AI 서버에 연결하지 못했어요. 서버 실행 상태와 네트워크를 확인해 주세요.',
        _ => switch (e.response?.statusCode) {
          401 || 403 =>
            viaBackend
                ? '인증을 확인하지 못했어요. 다시 시도하거나 로그인해 주세요.'
                : 'AI 서버 접근이 거부됐어요. 서버 설정을 확인해 주세요.',
          404 => '서버에서 이 기능을 아직 사용할 수 없어요.',
          422 || 400 => 'AI 요청 형식을 확인하지 못했어요. 입력 내용을 확인해 주세요.',
          429 => '요청이 많아요. 잠시 후 다시 시도해 주세요.',
          _ => 'AI 요청을 처리하지 못했어요. 잠시 후 다시 시도해 주세요.',
        },
      });
    } on FormatException {
      throw const AiApiException('AI 응답 형식을 확인하지 못했어요. 다시 시도해 주세요.');
    } on TypeError {
      throw const AiApiException('AI 응답 형식을 확인하지 못했어요. 다시 시도해 주세요.');
    } on StateError {
      throw const AiApiException('지원하지 않는 AI 문제 유형이에요. 다시 생성해 주세요.');
    }
  }

  Future<AiQuizBatch> generate({
    required String category,
    required String difficulty,
    required List<AiQuizType> types,
    required int countPerType,
    String? userId,
    String? domain,
    CancelToken? cancelToken,
  }) => _post(
    '/ai/quiz/generate',
    {
      'category': category.trim(),
      'difficulty': difficulty,
      'quiz_types': types.map((t) => t.code.toUpperCase()).toList(),
      'count_per_type': countPerType,
      'user_id': ?userId,
      if (domain?.trim().isNotEmpty == true) 'domain': domain!.trim(),
    },
    (json) => AiQuizBatch.fromJson(json, requestedCategory: category.trim()),
    cancelToken,
  );

  Future<AiGrade> grade({
    required AiQuizBatch batch,
    required AiQuiz quiz,
    required String answer,
    CancelToken? cancelToken,
  }) => _post(
    '/ai/quiz/grade',
    {
      'category': batch.category,
      'difficulty': batch.difficulty,
      'question': quiz.toJson(),
      'userAnswer': answer.trim(),
    },
    AiGrade.fromJson,
    cancelToken,
  );

  Future<AiJavaGrade> gradeJava({
    required String question,
    required String code,
    CancelToken? cancelToken,
  }) => _post(
    '/ai/java/grade',
    {'question': question, 'code': code.trim()},
    AiJavaGrade.fromJson,
    cancelToken,
  );

  Future<AiChatReply> chat(String message, {CancelToken? cancelToken}) => _post(
    '/ai/chat',
    {'message': message.trim(), 'context': null, 'useRag': null},
    AiChatReply.fromJson,
    cancelToken,
  );

  Future<AiExplanation> explain({
    required String question,
    required String answer,
    required String correctAnswer,
    CancelToken? cancelToken,
  }) => _post(
    '/ai/quiz/explain',
    {
      'question': question,
      'userAnswer': answer,
      'correctAnswer': correctAnswer,
    },
    AiExplanation.fromJson,
    cancelToken,
  );
}
