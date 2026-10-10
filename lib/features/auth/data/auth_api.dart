import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AuthApiException implements Exception {
  const AuthApiException(
    this.code,
    this.message, {
    this.status,
    this.fieldErrors = const {},
  });
  final String code;
  final String message;
  final int? status;
  final Map<String, String> fieldErrors;

  factory AuthApiException.fromDio(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    final fields = data is Map ? data['fieldErrors'] : null;
    final code = data is Map && data['code'] is String
        ? data['code'] as String
        : 'HTTP_ERROR';
    final message = switch (code) {
      'INVALID_CREDENTIALS' => '이메일 또는 비밀번호를 확인해 주세요.',
      'EMAIL_ALREADY_USED' => '이미 가입된 이메일입니다.',
      'NICKNAME_ALREADY_USED' => '이미 사용 중인 닉네임입니다.',
      'ACCOUNT_ALREADY_USED' => '이미 사용 중인 이메일 또는 닉네임입니다.',
      'EMAIL_NOT_VERIFIED' => '이메일 인증을 다시 진행해 주세요.',
      'INVALID_CODE' => '인증번호가 틀렸거나 만료되었습니다. 5회 오류 시 재전송이 필요합니다.',
      'INVALID_RESET_TOKEN' => '재설정 시간이 지났습니다. 인증번호를 다시 요청해 주세요.',
      'CODE_RATE_LIMITED' => '잠시 후 인증번호를 다시 요청해 주세요.',
      'MAIL_UNAVAILABLE' => '현재 인증 메일을 보낼 수 없습니다. 잠시 후 다시 시도해 주세요.',
      'INVALID_REFRESH_TOKEN' || 'UNAUTHORIZED' => '로그인이 만료되었습니다. 다시 로그인해 주세요.',
      _ => switch (status) {
        null => '서버에 연결할 수 없습니다. 네트워크와 API 주소를 확인해 주세요.',
        400 => '입력값을 확인해 주세요.',
        401 => '다시 로그인해 주세요.',
        403 => '접근 권한이 없습니다.',
        409 => '이미 사용 중인 정보입니다.',
        429 => '요청이 많습니다. 잠시 후 다시 시도해 주세요.',
        503 => '서버를 사용할 수 없습니다. 잠시 후 다시 시도해 주세요.',
        _ => '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.',
      },
    };
    return AuthApiException(
      code,
      message,
      status: status,
      fieldErrors: {
        if (fields is Map)
          for (final key in fields.keys)
            if (key is String) key: '입력값을 확인해 주세요.',
      },
    );
  }

  @override
  String toString() => 'AuthApiException($code)';
}

Map<String, dynamic> authObject(Object? data) {
  if (data is! Map<String, dynamic>) {
    throw const FormatException('Invalid auth response');
  }
  return data;
}

String authString(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is! String || value.isEmpty) {
    throw const FormatException('Invalid auth response');
  }
  return value;
}

int authInt(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is! int || value <= 0) {
    throw const FormatException('Invalid auth response');
  }
  return value;
}

class AuthUser {
  const AuthUser({
    required this.userId,
    required this.email,
    required this.nickname,
    required this.role,
  });
  final int userId;
  final String email;
  final String nickname;
  final String role;

  factory AuthUser.fromJson(Map<String, dynamic> data) => AuthUser(
    userId: authInt(data, 'userId'),
    email: authString(data, 'email'),
    nickname: authString(data, 'nickname'),
    role: authString(data, 'role'),
  );
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'email': email,
    'nickname': nickname,
    'role': role,
  };
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    required this.refreshExpiresAt,
    required this.user,
  });
  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiresAt;
  final DateTime refreshExpiresAt;
  final AuthUser user;

  factory AuthSession.fromResponse(Map<String, dynamic> data, DateTime now) {
    if (data['tokenType'] != 'Bearer') {
      throw const FormatException('Invalid token type');
    }
    return AuthSession(
      accessToken: authString(data, 'accessToken'),
      refreshToken: authString(data, 'refreshToken'),
      accessExpiresAt: now.add(
        Duration(seconds: authInt(data, 'accessExpiresInSeconds')),
      ),
      // 계약의 14일 회전 정책. 응답에는 refresh 만료 필드가 없습니다.
      refreshExpiresAt: now.add(const Duration(days: 14)),
      user: AuthUser.fromJson(authObject(data['user'])),
    );
  }
  factory AuthSession.fromJson(Map<String, dynamic> data) => AuthSession(
    accessToken: authString(data, 'accessToken'),
    refreshToken: authString(data, 'refreshToken'),
    accessExpiresAt: DateTime.parse(authString(data, 'accessExpiresAt')),
    refreshExpiresAt: DateTime.parse(authString(data, 'refreshExpiresAt')),
    user: AuthUser.fromJson(authObject(data['user'])),
  );
  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'accessExpiresAt': accessExpiresAt.toIso8601String(),
    'refreshExpiresAt': refreshExpiresAt.toIso8601String(),
    'user': user.toJson(),
  };
}

class CodeDelivery {
  const CodeDelivery(
    this.expiresInSeconds,
    this.resendAfterSeconds,
    this.message,
  );
  final int expiresInSeconds;
  final int resendAfterSeconds;
  final String message;
}

class ResetGrant {
  const ResetGrant(this.token, this.expiresInSeconds);
  final String token;
  final int expiresInSeconds;
}

class AuthApi {
  AuthApi(this.dio);
  final Dio dio;

  factory AuthApi.fromEnvironment() => AuthApi(
    Dio(
      BaseOptions(
        baseUrl: const String.fromEnvironment('API_BASE_URL'),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 10),
        followRedirects: false,
        contentType: 'application/json; charset=utf-8',
      ),
    ),
  );

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, Object> data,
    int status,
  ) async {
    final uri = Uri.tryParse(dio.options.baseUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        !['http', 'https'].contains(uri.scheme) ||
        (kReleaseMode && uri.scheme != 'https')) {
      throw const AuthApiException(
        'API_NOT_CONFIGURED',
        'API 주소가 설정되지 않았습니다. 개발 환경 설정을 확인해 주세요.',
      );
    }
    try {
      final response = await dio.post<Object?>(
        path,
        data: data,
        options: Options(extra: {'authRequired': false}),
      );
      if (response.statusCode != status) {
        throw const FormatException('Unexpected auth status');
      }
      // 204는 본문이 없으므로 JSON을 읽지 않습니다.
      return status == 204 ? <String, dynamic>{} : authObject(response.data);
    } on DioException catch (error) {
      throw AuthApiException.fromDio(error);
    } on FormatException {
      throw const AuthApiException('INVALID_RESPONSE', '서버 응답 형식을 확인할 수 없습니다.');
    }
  }

  Future<CodeDelivery> sendCode(
    String email, {
    bool passwordReset = false,
  }) async {
    final result = await _post(
      '/api/auth/${passwordReset ? 'password-resets' : 'email-verifications'}/send',
      {'email': email.trim()},
      202,
    );
    return CodeDelivery(
      authInt(result, 'expiresInSeconds'),
      authInt(result, 'resendAfterSeconds'),
      authString(result, 'message'),
    );
  }

  Future<void> confirmEmail(String email, String code) async {
    final result = await _post('/api/auth/email-verifications/confirm', {
      'email': email.trim(),
      'code': code,
    }, 200);
    if (result['verified'] != true) {
      throw const AuthApiException('INVALID_CODE', '이메일 인증을 완료하지 못했습니다.');
    }
  }

  Future<AuthUser> register({
    required String email,
    required String nickname,
    required String password,
    required bool serviceTermsAgreed,
    required bool privacyTermsAgreed,
  }) async => AuthUser.fromJson(
    await _post('/api/auth/register', {
      'email': email.trim(),
      'nickname': nickname.trim(),
      'password': password,
      'serviceTermsAgreed': serviceTermsAgreed,
      'privacyTermsAgreed': privacyTermsAgreed,
    }, 201),
  );
  Future<AuthSession> login(String email, String password) async =>
      AuthSession.fromResponse(
        await _post('/api/auth/login', {
          'email': email.trim(),
          'password': password,
        }, 200),
        DateTime.now(),
      );
  Future<AuthSession> refresh(String token) async => AuthSession.fromResponse(
    await _post('/api/auth/refresh', {'refreshToken': token}, 200),
    DateTime.now(),
  );
  Future<void> logout(String refreshToken, String accessToken) async {
    try {
      final response = await dio.post<Object?>(
        '/api/auth/logout',
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
          extra: {'authRequired': false},
        ),
      );
      if (response.statusCode != 204) {
        throw const AuthApiException(
          'INVALID_RESPONSE',
          '로그아웃 응답을 확인할 수 없습니다.',
        );
      }
    } on DioException catch (error) {
      throw AuthApiException.fromDio(error);
    }
  }

  Future<ResetGrant> confirmReset(String email, String code) async {
    final result = await _post('/api/auth/password-resets/confirm', {
      'email': email.trim(),
      'code': code,
    }, 200);
    return ResetGrant(
      authString(result, 'resetToken'),
      authInt(result, 'expiresInSeconds'),
    );
  }

  Future<void> completeReset(String token, String password) async {
    await _post('/api/auth/password-resets/complete', {
      'resetToken': token,
      'newPassword': password,
    }, 204);
  }
}
