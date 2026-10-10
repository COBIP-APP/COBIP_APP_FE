import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/auth_api.dart';
import '../data/token_store.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    required this.api,
    required TokenStore tokenStore,
    DateTime Function()? now,
  }) : _store = tokenStore,
       now = now ?? DateTime.now {
    api.dio.interceptors.add(
      InterceptorsWrapper(onRequest: _authorize, onError: _retryUnauthorized),
    );
  }
  final AuthApi api;
  final DateTime Function() now;
  final TokenStore _store;
  AuthSession? _session;
  Future<bool>? _refreshRequest;
  Future<void> _storageQueue = Future<void>.value();
  bool _isRestoring = true;
  bool _isBusy = false;
  bool _disposed = false;
  int _generation = 0;
  String? _errorMessage;

  AuthUser? get user => _session?.user;
  bool get isAuthenticated => _session != null;
  bool get isRestoring => _isRestoring;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _storage(Future<void> Function() operation) {
    // 토큰 회전 저장과 로그아웃 삭제가 뒤바뀌지 않게 직렬화합니다.
    final result = _storageQueue.then(
      (_) => operation(),
      onError: (Object _) => operation(),
    );
    _storageQueue = result;
    return result;
  }

  Future<void> restore() async {
    if (!_isRestoring) return;
    final generation = _generation;
    try {
      final saved = await _store.read();
      if (saved != null && generation == _generation && !_disposed) {
        _session = AuthSession.fromJson(authObject(jsonDecode(saved)));
        // 재시작 때 서버에서 확인하고 두 토큰을 함께 회전합니다.
        await refresh();
      }
    } catch (_) {
      if (generation == _generation) {
        await clearSession(message: '로그인 정보를 복원하지 못했습니다. 다시 로그인해 주세요.');
      }
    } finally {
      _isRestoring = false;
      _notify();
    }
  }

  Future<bool> login(
    String email,
    String password, {
    bool Function()? isCurrent,
  }) async {
    if (_isBusy || _disposed) return false;
    _isBusy = true;
    _errorMessage = null;
    final generation = ++_generation;
    _notify();
    try {
      final session = await api.login(email, password);
      if (_disposed ||
          generation != _generation ||
          isCurrent?.call() == false) {
        return false;
      }
      await _storage(() async {
        if (!_disposed &&
            generation == _generation &&
            isCurrent?.call() != false) {
          await _store.write(jsonEncode(session.toJson()));
        }
      });
      if (_disposed ||
          generation != _generation ||
          isCurrent?.call() == false) {
        if (generation == _generation) await clearSession();
        return false;
      }
      _session = session;
      return true;
    } on AuthApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      await clearSession(message: '로그인 정보를 안전하게 저장하지 못했습니다. 다시 시도해 주세요.');
      return false;
    } finally {
      _isBusy = false;
      _notify();
    }
  }

  Future<bool> refresh() {
    if (_refreshRequest != null) return _refreshRequest!;
    final request = _refresh();
    _refreshRequest = request;
    request.whenComplete(() {
      if (identical(_refreshRequest, request)) _refreshRequest = null;
    });
    return request;
  }

  Future<bool> _refresh() async {
    final current = _session;
    final generation = _generation;
    if (_disposed || current == null) return false;
    try {
      if (!now().isBefore(current.refreshExpiresAt)) {
        await clearSession(message: '로그인이 만료되었습니다. 다시 로그인해 주세요.');
        return false;
      }
      final session = await api.refresh(current.refreshToken);
      if (_disposed || generation != _generation) return false;
      await _storage(() async {
        if (!_disposed && generation == _generation) {
          await _store.write(jsonEncode(session.toJson()));
        }
      });
      if (_disposed || generation != _generation) return false;
      _session = session;
      _notify();
      return true;
    } catch (_) {
      if (generation == _generation) {
        await clearSession(message: '로그인이 만료되었습니다. 다시 로그인해 주세요.');
      }
      return false;
    }
  }

  Future<void> clearSession({String? message}) async {
    ++_generation;
    _session = null;
    _errorMessage = message;
    _notify();
    try {
      await _storage(_store.clear);
    } catch (_) {
      _errorMessage = '저장된 로그인 정보를 지우지 못했습니다. 앱 설정을 확인해 주세요.';
      _notify();
    }
  }

  Future<void> logout() async {
    if (_isBusy) return;
    _isBusy = true;
    _notify();
    String? failure;
    try {
      // 회전 중인 토큰이 있다면 최신 쌍으로 서버 세션을 종료합니다.
      if (_refreshRequest != null) await _refreshRequest;
      var current = _session;
      if (current != null) {
        if (!now().isBefore(current.accessExpiresAt)) {
          if (!await refresh()) return;
          current = _session!;
        }
        try {
          await api.logout(current.refreshToken, current.accessToken);
        } on AuthApiException catch (error) {
          if (error.status != 401 || !await refresh()) rethrow;
          current = _session!;
          await api.logout(current.refreshToken, current.accessToken);
        }
      }
    } on AuthApiException catch (error) {
      failure = '${error.message} 이 기기에서는 로그아웃했습니다. 서버 세션 종료는 확인되지 않았습니다.';
    } catch (_) {
      failure = '서버 로그아웃을 확인하지 못했습니다. 이 기기의 로그인 정보는 제거했습니다.';
    } finally {
      await clearSession(message: failure);
      _isBusy = false;
      _notify();
    }
  }

  void _authorize(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['authRequired'] == false) {
      handler.next(options);
      return;
    }
    if (_session != null && !now().isBefore(_session!.accessExpiresAt)) {
      await refresh();
    }
    if (_session == null || _disposed) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: const AuthApiException('UNAUTHORIZED', '로그인이 필요합니다.'),
        ),
      );
      return;
    }
    options.headers['Authorization'] = 'Bearer ${_session!.accessToken}';
    options.extra['authGeneration'] = _generation;
    handler.next(options);
  }

  void _retryUnauthorized(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final options = error.requestOptions;
    if (error.response?.statusCode != 401 ||
        options.extra['authRequired'] == false) {
      handler.next(error);
      return;
    }
    if (options.extra['authGeneration'] != _generation) {
      handler.next(error);
      return;
    }
    if (options.extra['authRetried'] == true) {
      await clearSession(message: '다시 로그인해 주세요.');
      handler.next(error);
      return;
    }
    final hasNewToken =
        _session != null &&
        options.headers['Authorization'] != 'Bearer ${_session!.accessToken}';
    if (!hasNewToken && !await refresh()) {
      handler.next(error);
      return;
    }
    if (_session == null) {
      handler.next(error);
      return;
    }
    options.extra['authRetried'] = true;
    options.headers['Authorization'] = 'Bearer ${_session!.accessToken}';
    try {
      handler.resolve(await api.dio.fetch<Object?>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    api.dio.close(force: true);
    super.dispose();
  }
}
