import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/auth_api.dart';
import 'auth_validators.dart';

class EmailVerificationViewModel extends ChangeNotifier {
  EmailVerificationViewModel(
    this.api, {
    this.passwordReset = false,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;
  final AuthApi api;
  final bool passwordReset;
  final DateTime Function() _now;
  Timer? _timer;
  int _revision = 0;
  bool _disposed = false;
  String _email = '';
  bool _isBusy = false;
  bool _isSending = false;
  bool _isCodeSent = false;
  bool _isVerified = false;
  int _failedAttempts = 0;
  DateTime? _codeExpiresAt;
  DateTime? _resendAt;
  DateTime? _verifiedExpiresAt;
  DateTime? _resetExpiresAt;
  String? _resetToken;
  String? _errorMessage;
  String? _codeError;
  String? _message;

  bool get isBusy => _isBusy;
  bool get isSending => _isBusy && _isSending;
  bool get isConfirming => _isBusy && !_isSending;
  bool get isCodeSent => _isCodeSent && codeSeconds > 0;
  bool get isVerified => _isVerified && _remaining(_verifiedExpiresAt) > 0;
  bool get hasResetGrant => _resetToken != null && resetSeconds > 0;
  int get codeSeconds => _remaining(_codeExpiresAt);
  int get resendSeconds => _remaining(_resendAt);
  int get resetSeconds => _remaining(_resetExpiresAt);
  bool get canSend =>
      !_isBusy &&
      !isVerified &&
      resendSeconds == 0 &&
      validateEmail(_email) == null;
  bool get canConfirm =>
      isCodeSent && !_isBusy && !isVerified && !hasResetGrant;
  String? get errorMessage => _errorMessage;
  String? get codeError => _codeError;
  String? get message => _message;

  int _remaining(DateTime? deadline) => deadline == null
      ? 0
      : ((deadline.difference(_now()).inMilliseconds / 1000).ceil()).clamp(
          0,
          86400,
        );
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool _current(int revision) => !_disposed && revision == _revision;

  void emailChanged(String value) {
    final email = value.trim().toLowerCase();
    if (email == _email) return;
    _email = email;
    ++_revision;
    _isBusy = false;
    _isCodeSent = false;
    _isVerified = false;
    _codeExpiresAt = _resendAt = _verifiedExpiresAt = null;
    _resetToken = null;
    _resetExpiresAt = null;
    _errorMessage = _codeError = _message = null;
    _failedAttempts = 0;
    _timer?.cancel();
    _notify();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isVerified && !isVerified) {
        _isVerified = false;
        _errorMessage = '이메일 인증 유효기간이 지났습니다. 다시 인증해 주세요.';
      }
      if (_resetToken != null && !hasResetGrant) {
        _resetToken = null;
        _errorMessage = '비밀번호 재설정 시간이 지났습니다. 인증번호를 다시 요청해 주세요.';
      }
      if (_isCodeSent && codeSeconds == 0 && !_isVerified && !hasResetGrant) {
        _isCodeSent = false;
        _codeError = '인증번호가 만료되었습니다. 다시 요청해 주세요.';
      }
      if (codeSeconds == 0 &&
          resendSeconds == 0 &&
          !isVerified &&
          !hasResetGrant) {
        _timer?.cancel();
      }
      _notify();
    });
  }

  Future<bool> send() async {
    if (!canSend) return false;
    final revision = ++_revision;
    final email = _email;
    _isBusy = true;
    _isSending = true;
    _isCodeSent = _isVerified = false;
    _resetToken = null;
    _resetExpiresAt = _verifiedExpiresAt = _codeExpiresAt = null;
    _errorMessage = _codeError = _message = null;
    _failedAttempts = 0;
    _notify();
    try {
      final result = await api.sendCode(email, passwordReset: passwordReset);
      if (!_current(revision)) return false;
      _codeExpiresAt = _now().add(Duration(seconds: result.expiresInSeconds));
      _resendAt = _now().add(Duration(seconds: result.resendAfterSeconds));
      _isCodeSent = true;
      _message = result.message;
      _startTimer();
      return true;
    } on AuthApiException catch (error) {
      if (_current(revision)) _errorMessage = error.message;
      return false;
    } catch (_) {
      if (_current(revision)) _errorMessage = '서버 응답을 확인하지 못했습니다. 다시 요청해 주세요.';
      return false;
    } finally {
      if (_current(revision)) {
        _isBusy = false;
        _notify();
      }
    }
  }

  Future<bool> confirm(String code) async {
    if (!canConfirm) return false;
    if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) {
      _codeError = '인증번호 6자리를 입력해 주세요';
      _notify();
      return false;
    }
    final revision = _revision;
    _isBusy = true;
    _isSending = false;
    _errorMessage = _codeError = null;
    _notify();
    try {
      if (passwordReset) {
        final grant = await api.confirmReset(_email, code);
        if (!_current(revision)) return false;
        _resetToken = grant.token;
        _resetExpiresAt = _now().add(Duration(seconds: grant.expiresInSeconds));
      } else {
        await api.confirmEmail(_email, code);
        if (!_current(revision)) return false;
        _isVerified = true;
        // confirm 응답에는 TTL이 없어 계약의 30분을 적용합니다.
        _verifiedExpiresAt = _now().add(const Duration(minutes: 30));
      }
      _isCodeSent = false;
      _codeExpiresAt = null;
      _startTimer();
      return true;
    } on AuthApiException catch (error) {
      if (_current(revision)) {
        _codeError = error.message;
        if (error.code == 'INVALID_CODE' && ++_failedAttempts >= 5) {
          _isCodeSent = false;
          _codeExpiresAt = null;
          _codeError = '인증번호 오류가 5회 발생했습니다. 새 번호를 요청해 주세요.';
        }
      }
      return false;
    } catch (_) {
      if (_current(revision)) _errorMessage = '서버 응답을 확인하지 못했습니다.';
      return false;
    } finally {
      if (_current(revision)) {
        _isBusy = false;
        _notify();
      }
    }
  }

  void revokeVerification() {
    _isVerified = false;
    _verifiedExpiresAt = null;
    _errorMessage = '이메일 인증을 다시 진행해 주세요.';
    _notify();
  }

  void discardResetGrant() {
    ++_revision;
    _resetToken = null;
    _resetExpiresAt = null;
    _isCodeSent = false;
    _isBusy = false;
    _notify();
  }

  Future<bool> completeReset(String password) async {
    if (_isBusy || !hasResetGrant || validatePassword(password) != null) {
      return false;
    }
    final revision = _revision;
    final token = _resetToken!;
    _isBusy = true;
    _errorMessage = null;
    _notify();
    try {
      await api.completeReset(token, password);
      if (!_current(revision)) return false;
      _resetToken = null;
      _resetExpiresAt = null;
      return true;
    } on AuthApiException catch (error) {
      if (_current(revision)) {
        _errorMessage = error.message;
        if (error.code == 'INVALID_RESET_TOKEN') {
          _resetToken = null;
          _resetExpiresAt = null;
        }
      }
      return false;
    } catch (_) {
      if (_current(revision)) {
        _errorMessage = '변경 결과를 확인하지 못했습니다. 다시 로그인하거나 인증을 재시도해 주세요.';
      }
      return false;
    } finally {
      if (_current(revision)) {
        _isBusy = false;
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_revision;
    _resetToken = null;
    _timer?.cancel();
    super.dispose();
  }
}
