import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'learning_models.dart';
import '../../problems/data/ai_models.dart';

class LearningApiException implements Exception {
  const LearningApiException(this.message, {this.status});
  final String message;
  final int? status;
  @override
  String toString() => message;
}

Map<String, dynamic> _object(Object? v) {
  if (v is! Map<String, dynamic>) {
    throw const FormatException('Expected object');
  }
  return v;
}

List<dynamic> _list(Object? v) {
  if (v is! List) throw const FormatException('Expected list');
  return v;
}

int _id(Object? v) {
  if (v is! int || v <= 0) throw const FormatException('Invalid id');
  return v;
}

int? _optionalId(Object? v) => v == null ? null : _id(v);
String _text(Object? v) {
  if (v is! String || v.trim().isEmpty) {
    throw const FormatException('Invalid text');
  }
  return v;
}

String? _optionalText(Object? v) {
  if (v != null && v is! String) throw const FormatException('Invalid text');
  return v as String?;
}

DateTime _date(Object? v) {
  if (v is! String || !RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(v)) {
    throw const FormatException('Invalid date');
  }
  return DateTime.parse(v);
}

T _enum<T>(Iterable<T> values, String Function(T) code, Object? v) =>
    values.firstWhere(
      (value) => code(value) == v,
      orElse: () => throw const FormatException('Unsupported enum'),
    );

List<LearningMedia> _media(Object? v) => _list(v).map((value) {
  final m = _object(value);
  return LearningMedia(
    id: _id(m['id']),
    originalName: _text(m['originalName']),
    objectKey: _text(m['objectKey']),
    altText: _optionalText(m['altText']),
  );
}).toList();
TemplateSection _section(Object? value) {
  final s = _object(value);
  return TemplateSection(
    id: _id(s['id']),
    parentId: _optionalId(s['parentId']),
    title: _text(s['title']),
    body: _optionalText(s['body']),
    exampleCode: _optionalText(s['exampleCode']),
    media: _media(s['media']),
    children: _list(s['children']).map(_section).toList(),
  );
}

LearningTemplate _template(Object? value, {bool detail = false}) {
  final t = _object(value);
  if (t['published'] != true) {
    throw const FormatException('Unpublished template');
  }
  return LearningTemplate(
    id: _id(t['id']),
    title: _text(t['title']),
    summary: _optionalText(t['summary']) ?? '',
    description: _optionalText(t['description']) ?? '',
    categoryId: _id(t['categoryId']),
    languageId: _optionalId(t['languageId']),
    difficulty: _enum(
      LearningDifficulty.values,
      (v) => v.code,
      t['difficulty'],
    ),
    sections: detail ? _list(t['sections']).map(_section).toList() : const [],
    media: _media(t['media']),
    createdAt: t['createdAt'] == null ? null : _date(t['createdAt']),
  );
}

LearningQuestion _question(Object? value, {int? ownerId}) {
  final q = _object(value);
  if (q['published'] is! bool ||
      (q['published'] != true &&
          (ownerId == null || q['createdBy'] != ownerId))) {
    throw const FormatException('Unpublished question');
  }
  final type = _enum(
    LearningQuestionType.values,
    (v) => v.code,
    q['questionType'],
  );
  final choices =
      (q['choiceOptions'] == null ? <dynamic>[] : _list(q['choiceOptions']))
          .map(
            (c) => LearningChoice(
              _text(_object(c)['key']),
              _text(_object(c)['text']),
            ),
          )
          .toList();
  if (type.hasChoices &&
      (choices.isEmpty ||
          choices.map((c) => c.key).toSet().length != choices.length)) {
    throw const FormatException('Unsupported choice options');
  }
  final score = q['passScore'];
  if (score is! int || score < 0 || score > 100) {
    throw const FormatException('Invalid pass score');
  }
  return LearningQuestion(
    id: _id(q['id']),
    createdBy: _optionalId(q['createdBy']),
    creatorNickname: _optionalText(q['creatorNickname']),
    published: q['published'] as bool,
    prompt: _text(q['prompt']),
    questionType: type,
    categoryId: _id(q['categoryId']),
    languageId: _optionalId(q['languageId']),
    languageCode: _optionalText(q['languageCode']),
    languageName: _optionalText(q['languageName']),
    generationTopic: _optionalText(q['generationTopic']),
    relatedTemplateId: _optionalId(q['relatedTemplateId']),
    relatedSectionId: _optionalId(q['relatedSectionId']),
    codeSnippet: _optionalText(q['codeSnippet']),
    choiceOptions: choices,
    explanation: _optionalText(q['explanation']),
    difficulty: _enum(
      LearningDifficulty.values,
      (v) => v.code,
      q['difficulty'],
    ),
    passScore: score,
    media: _media(q['media']),
    createdAt: q['createdAt'] == null ? null : _date(q['createdAt']),
  );
}

LearningProgress _progress(Object? value) {
  final p = _object(value);
  return LearningProgress(
    templateId: _id(p['templateId']),
    lastSectionId: _optionalId(p['lastSectionId']),
    startedAt: _date(p['startedAt']),
    lastStudiedAt: _date(p['lastStudiedAt']),
    completedAt: p['completedAt'] == null ? null : _date(p['completedAt']),
  );
}

LearningSubmission _submission(Object? value, int userId, int questionId) {
  final s = _object(value);
  if (s['userId'] != userId || s['questionId'] != questionId) {
    throw const FormatException('Submission identity mismatch');
  }
  final status = _text(s['gradingStatus']);
  if (!['PENDING', 'COMPLETED', 'FAILED'].contains(status)) {
    throw const FormatException('Invalid grading status');
  }
  final score = s['score'];
  if (score != null &&
      (score is! num || !score.isFinite || score < 0 || score > 100)) {
    throw const FormatException('Invalid score');
  }
  if (status == 'COMPLETED' && score == null) {
    throw const FormatException('Missing score');
  }
  return LearningSubmission(
    id: _id(s['id']),
    questionId: questionId,
    gradingStatus: status,
    gradingMethod: _optionalText(s['gradingMethod']),
    score: score as num?,
    feedback: _optionalText(s['feedback']),
    correctAnswer: _optionalText(s['correctAnswer']),
    explanation: _optionalText(s['explanation']),
    selectedChoiceKey: _optionalText(s['selectedChoiceKey']),
    answerText: _optionalText(s['answerText']),
    sourceCode: _optionalText(s['sourceCode']),
    submittedAt: _date(s['submittedAt']),
    gradedAt: s['gradedAt'] == null ? null : _date(s['gradedAt']),
  );
}

/// Uses the same authenticated Dio (Bearer + refresh) as login and home.
class LearningApi {
  LearningApi(this.dio);
  final Dio dio;

  Future<T> _request<T>(
    String path,
    T Function(Object?) decode, {
    String method = 'GET',
    Object? body,
    Map<String, dynamic>? query,
    int status = 200,
    Set<int> additionalStatuses = const {},
    Duration? receiveTimeout,
    CancelToken? cancelToken,
  }) async {
    final uri = Uri.tryParse(dio.options.baseUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        !['http', 'https'].contains(uri.scheme) ||
        (kReleaseMode && uri.scheme != 'https')) {
      throw const LearningApiException('API 주소가 설정되지 않았습니다.');
    }
    try {
      final response = await dio.request<Object?>(
        path,
        data: body,
        queryParameters: query,
        cancelToken: cancelToken,
        options: Options(
          method: method,
          receiveTimeout: receiveTimeout,
          extra: {'authRequired': true},
        ),
      );
      if (response.statusCode != status &&
          !additionalStatuses.contains(response.statusCode)) {
        throw const FormatException('Unexpected status');
      }
      return decode(response.data);
    } on FormatException {
      throw const LearningApiException('서버의 학습 데이터 형식을 확인할 수 없어요.');
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      throw LearningApiException(switch (e.response?.statusCode) {
        400 => '입력한 답안과 학습 정보를 확인해 주세요.',
        401 => '로그인이 만료되었습니다. 다시 로그인해 주세요.',
        403 => '이 학습 정보에 접근할 권한이 없습니다.',
        404 => '현재 공개된 학습이나 문제를 찾을 수 없습니다.',
        409 => '학습 정보가 변경되었습니다. 목록을 새로고침해 주세요.',
        _ => '서버에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.',
      }, status: e.response?.statusCode);
    }
  }

  Future<List<LearningLanguage>> languages({CancelToken? cancelToken}) =>
      _request(
        '/api/languages',
        (v) => _list(v).map((e) {
          final l = _object(e);
          return LearningLanguage(
            _id(l['id']),
            _text(l['code']),
            _text(l['name']),
          );
        }).toList(),
        cancelToken: cancelToken,
      );

  Future<List<LearningCategory>> categories({CancelToken? cancelToken}) =>
      _request('/api/categories', (v) {
        final result = <LearningCategory>[];
        void visit(Object? value, int? parent) {
          final c = _object(value);
          final id = _id(c['id']);
          if (_optionalId(c['parentId']) != parent ||
              result.any((e) => e.id == id)) {
            throw const FormatException('Invalid category tree');
          }
          result.add(
            LearningCategory(
              id,
              _text(c['code']),
              _text(c['name']),
              parentId: parent,
            ),
          );
          for (final child in _list(c['children'])) {
            visit(child, id);
          }
        }

        for (final root in _list(v)) {
          visit(root, null);
        }
        return result;
      }, cancelToken: cancelToken);

  Future<List<LearningTemplate>> templates({CancelToken? cancelToken}) =>
      _request(
        '/api/templates',
        (v) => _list(v).map((e) => _template(e)).toList(),
        query: {'publishedOnly': true},
        cancelToken: cancelToken,
      );
  Future<LearningTemplate> template(int id, {CancelToken? cancelToken}) =>
      _request('/api/templates/$id', (v) {
        final result = _template(v, detail: true);
        if (result.id != id) {
          throw const FormatException('Template identity mismatch');
        }
        return result;
      }, cancelToken: cancelToken);
  Future<List<LearningQuestion>> questions({
    int? templateId,
    int? sectionId,
    CancelToken? cancelToken,
  }) => _request(
    '/api/questions',
    (v) => _list(v).map(_question).toList(),
    query: {
      'publishedOnly': true,
      'templateId': ?templateId,
      'sectionId': ?sectionId,
    },
    cancelToken: cancelToken,
  );
  Future<LearningQuestion> question(
    int id, {
    int? ownerId,
    CancelToken? cancelToken,
  }) => _request('/api/questions/$id', (v) {
    final result = _question(v, ownerId: ownerId);
    if (result.id != id) {
      throw const FormatException('Question identity mismatch');
    }
    return result;
  }, cancelToken: cancelToken);

  // Keep the ordinary-user save contract; category carries the original topic.
  Future<LearningQuestion> saveGeneratedQuestion({
    required int userId,
    required String clientRequestId,
    required AiQuizBatch batch,
    required AiQuiz quiz,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _request(
        '/api/users/me/questions',
        (v) {
          final question = _question(v, ownerId: userId);
          if (question.createdBy != userId) {
            throw const FormatException('Creator identity mismatch');
          }
          return question;
        },
        method: 'POST',
        status: 201,
        additionalStatuses: {200},
        body: {
          'clientRequestId': clientRequestId,
          'category': batch.generationTopic,
          'difficulty': batch.difficulty,
          'question': quiz.toJson(),
        },
        cancelToken: cancelToken,
      );
    } on LearningApiException catch (e) {
      if (e.status == 404 || e.status == 405 || e.status == 501) {
        throw const LearningApiException(
          '문제 저장 기능이 아직 서버에 준비되지 않았어요. 저장되지 않았습니다.',
        );
      }
      rethrow;
    }
  }

  Future<List<LearningQuestion>> myQuestions(
    int userId, {
    CancelToken? cancelToken,
  }) async {
    try {
      return await _request('/api/users/me/questions', (v) {
        final result = _list(v)
            .map((q) => _question(q, ownerId: userId))
            .toList();
        if (result.any((q) => q.createdBy != userId) ||
            result.map((q) => q.id).toSet().length != result.length) {
          throw const FormatException('Invalid own questions');
        }
        return result;
      }, cancelToken: cancelToken);
    } on LearningApiException catch (e) {
      if (e.status == 404 || e.status == 405 || e.status == 501) {
        throw const LearningApiException('내가 만든 문제 조회 기능이 아직 서버에 준비되지 않았어요.');
      }
      rethrow;
    }
  }

  Future<void> deleteMyQuestion(
    int questionId, {
    CancelToken? cancelToken,
  }) async {
    try {
      await _request<void>(
        '/api/users/me/questions/$questionId',
        (_) {}, // 204 has no response body to decode.
        method: 'DELETE',
        status: 204,
        cancelToken: cancelToken,
      );
    } on LearningApiException catch (error) {
      if (error.status == 404) {
        throw const LearningApiException(
          '삭제할 수 없는 문제이거나 이미 삭제된 문제예요. 목록을 새로고침해 주세요.',
          status: 404,
        );
      }
      rethrow;
    }
  }

  Future<List<LearningProgress>> progress({CancelToken? cancelToken}) =>
      _request(
        '/api/users/me/progress',
        (v) => _list(v).map(_progress).toList(),
        cancelToken: cancelToken,
      );
  Future<Set<int>> bookmarks(int userId, {CancelToken? cancelToken}) =>
      _request(
        '/api/users/$userId/bookmarks',
        (v) => _list(v).map((e) {
          final b = _object(e);
          if (b['userId'] != userId) {
            throw const FormatException('Bookmark identity mismatch');
          }
          return _id(b['templateId']);
        }).toSet(),
        cancelToken: cancelToken,
      );
  Future<void> bookmark(
    int userId,
    int id,
    bool save, {
    CancelToken? cancelToken,
  }) => _request<void>(
    '/api/users/$userId/bookmarks/templates/$id',
    (v) {
      if (save &&
          (_object(v)['userId'] != userId || _object(v)['templateId'] != id)) {
        throw const FormatException('Bookmark identity mismatch');
      }
    },
    method: save ? 'PUT' : 'DELETE',
    status: save ? 200 : 204,
    cancelToken: cancelToken,
  );
  Future<LearningProgress> saveProgress(
    int userId,
    int id,
    int sectionId, {
    bool? completed,
    CancelToken? cancelToken,
  }) => _request(
    '/api/users/$userId/progress/templates/$id',
    (v) {
      if (_object(v)['userId'] != userId || _object(v)['templateId'] != id) {
        throw const FormatException('Progress identity mismatch');
      }
      return _progress(v);
    },
    method: 'PUT',
    body: {'lastSectionId': sectionId, 'completed': ?completed},
    cancelToken: cancelToken,
  );
  Future<LearningSubmission?> latest(
    int userId,
    int questionId, {
    CancelToken? cancelToken,
  }) async {
    try {
      return await _request(
        '/api/questions/$questionId/submissions/latest',
        (v) => _submission(v, userId, questionId),
        query: {'userId': userId},
        cancelToken: cancelToken,
      );
    } on LearningApiException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  Future<LearningSubmission> submit(
    int userId,
    LearningQuestion question,
    String answer, {
    CancelToken? cancelToken,
  }) {
    final field = switch (question.questionType) {
      LearningQuestionType.multipleChoice ||
      LearningQuestionType.ox => 'selectedChoiceKey',
      LearningQuestionType.codeWriting => 'sourceCode',
      _ => 'answerText',
    };
    return _request(
      '/api/questions/${question.id}/submissions',
      (v) => _submission(v, userId, question.id),
      method: 'POST',
      status: 201,
      body: {'userId': userId, field: answer},
      receiveTimeout: const Duration(minutes: 5),
      cancelToken: cancelToken,
    );
  }
}
