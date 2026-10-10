import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../auth/data/auth_api.dart';

class HomeApiException implements Exception {
  const HomeApiException(this.code, this.message, {this.status});

  final String code;
  final String message;
  final int? status;

  factory HomeApiException.fromDio(DioException error) {
    if (error.error is FormatException) {
      return const HomeApiException(
        'INVALID_RESPONSE',
        '서버의 학습 응답 형식을 확인할 수 없습니다.',
      );
    }
    final authError = error.error;
    final status =
        error.response?.statusCode ??
        (authError is AuthApiException && authError.code == 'UNAUTHORIZED'
            ? 401
            : null);
    return HomeApiException('HTTP_ERROR', switch (status) {
      null => '서버에 연결할 수 없습니다. 네트워크와 API 주소를 확인해 주세요.',
      401 => '로그인이 만료되었습니다. 다시 로그인해 주세요.',
      403 => '학습 정보를 조회할 권한이 없습니다.',
      _ => '학습 정보를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.',
    }, status: status);
  }

  @override
  String toString() => 'HomeApiException($code)';
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Invalid home response');
  }
  return value;
}

int _positiveInt(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is! int || value <= 0) {
    throw const FormatException('Invalid home response');
  }
  return value;
}

String? _optionalString(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value != null && value is! String) {
    throw const FormatException('Invalid home response');
  }
  return value as String?;
}

DateTime _date(Map<String, dynamic> data, String key) {
  final value = data[key];
  final date = value is String ? DateTime.tryParse(value) : null;
  if (date == null ||
      !RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(value as String)) {
    throw const FormatException('Invalid home response');
  }
  return date;
}

class HomeTemplate {
  const HomeTemplate({
    required this.id,
    required this.title,
    required this.published,
    this.summary,
    this.categoryCode,
    this.categoryName,
    this.languageCode,
    this.languageName,
  });

  final int id;
  final String title;
  final bool published;
  final String? summary;
  final String? categoryCode;
  final String? categoryName;
  final String? languageCode;
  final String? languageName;

  factory HomeTemplate.fromJson(Map<String, dynamic> data) {
    final title = data['title'];
    final published = data['published'];
    if (title is! String || title.trim().isEmpty || published is! bool) {
      throw const FormatException('Invalid home response');
    }
    return HomeTemplate(
      id: _positiveInt(data, 'id'),
      title: title,
      published: published,
      summary: _optionalString(data, 'summary'),
      categoryCode: _optionalString(data, 'categoryCode'),
      categoryName: _optionalString(data, 'categoryName'),
      languageCode: _optionalString(data, 'languageCode'),
      languageName: _optionalString(data, 'languageName'),
    );
  }
}

class HomeProgress {
  const HomeProgress({
    required this.userId,
    required this.templateId,
    required this.startedAt,
    required this.lastStudiedAt,
    this.lastSectionId,
    this.completedAt,
  });

  final int userId;
  final int templateId;
  final int? lastSectionId;
  final DateTime startedAt;
  final DateTime lastStudiedAt;
  final DateTime? completedAt;

  factory HomeProgress.fromJson(Map<String, dynamic> data) => HomeProgress(
    userId: _positiveInt(data, 'userId'),
    templateId: _positiveInt(data, 'templateId'),
    lastSectionId: data['lastSectionId'] == null
        ? null
        : _positiveInt(data, 'lastSectionId'),
    startedAt: _date(data, 'startedAt'),
    lastStudiedAt: _date(data, 'lastStudiedAt'),
    completedAt: data['completedAt'] == null
        ? null
        : _date(data, 'completedAt'),
  );
}

class HomeApi {
  HomeApi(this.dio);

  final Dio dio;

  static const _invalidResponse = HomeApiException(
    'INVALID_RESPONSE',
    '서버의 학습 응답 형식을 확인할 수 없습니다.',
  );

  Future<Object?> _get(
    String path, {
    Map<String, Object>? queryParameters,
  }) async {
    final uri = Uri.tryParse(dio.options.baseUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        !['http', 'https'].contains(uri.scheme) ||
        (kReleaseMode && uri.scheme != 'https')) {
      throw const HomeApiException(
        'API_NOT_CONFIGURED',
        'API 주소가 설정되지 않았습니다. 개발 환경 설정을 확인해 주세요.',
      );
    }
    try {
      final response = await dio.get<Object?>(
        path,
        queryParameters: queryParameters,
        options: Options(extra: {'authRequired': true}),
      );
      if (response.statusCode != 200) throw _invalidResponse;
      return response.data;
    } on DioException catch (error) {
      throw HomeApiException.fromDio(error);
    }
  }

  Future<List<HomeTemplate>> fetchTemplates() async {
    final data = await _get(
      '/api/templates',
      queryParameters: {'publishedOnly': true},
    );
    try {
      if (data is! List) throw const FormatException('Invalid home response');
      final templates = data.map(
        (item) => HomeTemplate.fromJson(_object(item)),
      );
      return List.unmodifiable(
        templates.where((template) => template.published),
      );
    } on FormatException {
      throw _invalidResponse;
    }
  }

  Future<HomeProgress?> fetchProgress(int userId, int templateId) async {
    if (userId <= 0 || templateId <= 0) {
      throw const HomeApiException('INVALID_REQUEST', '학습 식별자를 확인할 수 없습니다.');
    }
    try {
      final data = await _get(
        '/api/users/$userId/progress/templates/$templateId',
      );
      final progress = HomeProgress.fromJson(_object(data));
      if (progress.userId != userId || progress.templateId != templateId) {
        throw _invalidResponse;
      }
      return progress;
    } on HomeApiException catch (error) {
      if (error.status == 404) return null;
      rethrow;
    } on FormatException {
      throw _invalidResponse;
    }
  }
}
