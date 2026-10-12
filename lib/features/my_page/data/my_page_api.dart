import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../auth/data/auth_api.dart';
import '../../learning/data/learning_api.dart';
import '../../learning/data/learning_models.dart';
import '../../learning/data/learning_destination.dart';

DateTime _date(Object? value) {
  if (value is! String || !RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(value)) {
    throw const FormatException('Invalid date');
  }
  return DateTime.parse(value);
}

String? _optionalText(Object? value) {
  if (value != null && value is! String) {
    throw const FormatException('Invalid text');
  }
  return value as String?;
}

class MyProfile {
  MyProfile.fromJson(Map<String, dynamic> data)
    : user = AuthUser.fromJson(data),
      createdAt = _date(data['createdAt']);
  final AuthUser user;
  final DateTime createdAt;
}

class MyLearningRecord {
  MyLearningRecord.fromJson(Map<String, dynamic> data)
    : templateId = authInt(data, 'templateId'),
      title = authString(data, 'title'),
      categoryName = authString(data, 'categoryName'),
      languageName = _optionalText(data['languageName']),
      lastSectionId = data['lastSectionId'] == null
          ? null
          : authInt(data, 'lastSectionId'),
      lastSectionTitle = _optionalText(data['lastSectionTitle']),
      lastStudiedAt = _date(data['lastStudiedAt']),
      completedAt = data['completedAt'] == null
          ? null
          : _date(data['completedAt']);
  final int templateId;
  final String title, categoryName;
  final String? languageName, lastSectionTitle;
  final int? lastSectionId;
  final DateTime lastStudiedAt;
  final DateTime? completedAt;
}

class MyBookmark {
  MyBookmark.fromJson(Map<String, dynamic> data)
    : userId = authInt(data, 'userId'),
      templateId = authInt(data, 'templateId'),
      title = authString(data, 'title'),
      summary = _optionalText(data['summary']),
      difficulty = LearningDifficulty.values.firstWhere(
        (value) => value.code == data['difficulty'],
        orElse: () => throw const FormatException('Invalid difficulty'),
      ),
      createdAt = _date(data['createdAt']);
  final int userId, templateId;
  final String title;
  final String? summary;
  final LearningDifficulty difficulty;
  final DateTime createdAt;
}

class MyRecentResult {
  const MyRecentResult(this.question, this.submission);
  final LearningQuestion question;
  final LearningSubmission submission;
}

/// Uses existing BE contracts and the authenticated Dio; no sample fallback.
class MyPageApi {
  MyPageApi(this.dio) : learning = LearningApi(dio);
  final Dio dio;
  final LearningApi learning;

  Future<T> _get<T>(
    String path,
    T Function(Object?) decode,
    CancelToken cancel,
  ) async {
    final uri = Uri.tryParse(dio.options.baseUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        !['http', 'https'].contains(uri.scheme) ||
        (kReleaseMode && uri.scheme != 'https')) {
      throw const LearningApiException('API 주소가 설정되지 않았습니다.');
    }
    try {
      final response = await dio.get<Object?>(
        path,
        cancelToken: cancel,
        options: Options(extra: {'authRequired': true}),
      );
      if (response.statusCode != 200) {
        throw const FormatException('Unexpected response');
      }
      return decode(response.data);
    } on FormatException {
      throw const LearningApiException('서버 데이터 형식을 확인할 수 없어요.');
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      throw LearningApiException(switch (error.response?.statusCode) {
        401 => '로그인이 만료되었습니다. 다시 로그인해 주세요.',
        403 => '이 기록에 접근할 권한이 없습니다.',
        _ => '정보를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
      }, status: error.response?.statusCode);
    }
  }

  List<T> _list<T>(Object? value, T Function(Map<String, dynamic>) decode) {
    if (value is! List) throw const FormatException('Invalid list');
    return List.unmodifiable(value.map((item) => decode(authObject(item))));
  }

  Future<MyProfile> profile(int userId, CancelToken cancel) =>
      _get('/api/users/me', (value) {
        final profile = MyProfile.fromJson(authObject(value));
        if (profile.user.userId != userId) {
          throw const FormatException('Profile identity mismatch');
        }
        return profile;
      }, cancel);

  Future<List<MyLearningRecord>> progress(CancelToken cancel) => _get(
    '/api/users/me/progress',
    (value) => _list(value, MyLearningRecord.fromJson),
    cancel,
  );

  Future<List<MyBookmark>> bookmarks(int userId, CancelToken cancel) =>
      _get('/api/users/$userId/bookmarks', (value) {
        final items = _list(value, MyBookmark.fromJson);
        if (items.any((item) => item.userId != userId)) {
          throw const FormatException('Bookmark identity mismatch');
        }
        return items;
      }, cancel);

  Future<List<MyRecentResult>> recent(int userId, CancelToken cancel) async {
    final questions = await learning.questions(cancelToken: cancel);
    final results = <MyRecentResult>[];
    // Latest-only endpoint: bounded requests, never infer a lifetime history.
    for (var i = 0; i < questions.length; i += 4) {
      if (cancel.isCancelled) throw cancel.cancelError!;
      final batch = await Future.wait(
        questions.skip(i).take(4).map((question) async {
          final submission = await learning.latest(
            userId,
            question.id,
            cancelToken: cancel,
          );
          return submission == null
              ? null
              : MyRecentResult(question, submission);
        }),
      );
      results.addAll(batch.whereType<MyRecentResult>());
    }
    results.sort((a, b) {
      final date = b.submission.submittedAt.compareTo(a.submission.submittedAt);
      return date != 0 ? date : b.submission.id.compareTo(a.submission.id);
    });
    return List.unmodifiable(results);
  }

  Future<LearningDestination> destination(
    int templateId,
    int? sectionId,
    CancelToken cancel,
  ) => resolveLearningDestination(learning, templateId, sectionId, cancel);
}
