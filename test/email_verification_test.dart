import 'dart:async';

import 'package:cobip_app_fe/features/auth/presentation/email_verification_view_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_support.dart';

void main() {
  test('서버 TTL·재전송 대기·인증 성공·30분 만료를 적용한다', () async {
    var now = DateTime(2026, 10, 10);
    final adapter = TestAuthAdapter();
    final verification = EmailVerificationViewModel(
      testApi(adapter),
      now: () => now,
    );
    addTearDown(verification.dispose);
    verification.emailChanged('member@example.com');
    expect(await verification.send(), isTrue);
    expect(verification.codeSeconds, 300);
    expect(verification.resendSeconds, 60);
    expect(await verification.send(), isFalse);
    expect(verification.isVerified, isFalse);
    expect(await verification.confirm('012345'), isTrue);
    expect(adapter.requests.last.data['code'], '012345');
    expect(verification.isVerified, isTrue);
    now = now.add(const Duration(minutes: 30));
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(verification.isVerified, isFalse);
    expect(verification.errorMessage, contains('유효기간'));
  });

  test('코드 만료와 재전송은 기존 코드·인증을 무효화한다', () async {
    var now = DateTime(2026, 10, 10);
    final adapter = TestAuthAdapter();
    final verification = EmailVerificationViewModel(
      testApi(adapter),
      now: () => now,
    );
    addTearDown(verification.dispose);
    verification.emailChanged('member@example.com');
    await verification.send();
    now = now.add(const Duration(seconds: 301));
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(verification.canConfirm, isFalse);
    expect(verification.codeError, contains('만료'));
    final before = adapter.requests.length;
    expect(await verification.confirm('012345'), isFalse);
    expect(adapter.requests.length, before);
    expect(await verification.send(), isTrue);
    expect(verification.isVerified, isFalse);
  });

  test('서버 INVALID_CODE 5회 이후 확인을 막고 재전송을 요구한다', () async {
    final adapter = TestAuthAdapter();
    final verification = EmailVerificationViewModel(testApi(adapter));
    addTearDown(verification.dispose);
    verification.emailChanged('member@example.com');
    await verification.send();
    adapter.handle = (_) async => jsonResponse({'code': 'INVALID_CODE'}, 400);
    for (var attempt = 0; attempt < 5; attempt++) {
      expect(await verification.confirm('000001'), isFalse);
      expect(verification.isVerified, isFalse);
    }
    expect(verification.canConfirm, isFalse);
    expect(verification.codeError, contains('5회'));
    expect(adapter.requests.length, 6);
  });

  test('verified false와 형식만 맞는 코드를 성공으로 처리하지 않는다', () async {
    final adapter = TestAuthAdapter();
    final verification = EmailVerificationViewModel(testApi(adapter));
    addTearDown(verification.dispose);
    verification.emailChanged('member@example.com');
    await verification.send();
    final count = adapter.requests.length;
    expect(await verification.confirm('123'), isFalse);
    expect(adapter.requests.length, count);
    adapter.handle = (_) async => jsonResponse({'verified': false}, 200);
    expect(await verification.confirm('012345'), isFalse);
    expect(verification.isVerified, isFalse);
  });

  test('늦은 발송 응답은 바뀐 이메일 상태를 덮어쓰지 않는다', () async {
    final first = Completer<ResponseBody>();
    final adapter = TestAuthAdapter(
      handle: (options) async => options.data['email'] == 'old@example.com'
          ? first.future
          : jsonResponse({
              'message': 'sent',
              'expiresInSeconds': 200,
              'resendAfterSeconds': 20,
            }, 202),
    );
    final verification = EmailVerificationViewModel(testApi(adapter));
    addTearDown(verification.dispose);
    verification.emailChanged('old@example.com');
    final oldRequest = verification.send();
    verification.emailChanged('new@example.com');
    expect(await verification.send(), isTrue);
    first.complete(
      jsonResponse({
        'message': 'old',
        'expiresInSeconds': 300,
        'resendAfterSeconds': 60,
      }, 202),
    );
    expect(await oldRequest, isFalse);
    expect(verification.message, 'sent');
    expect(verification.resendSeconds, lessThanOrEqualTo(20));
    expect(verification.isVerified, isFalse);
  });

  test('늦은 확인 응답과 이메일 변경은 새 이메일을 인증하지 않는다', () async {
    final adapter = TestAuthAdapter();
    final verification = EmailVerificationViewModel(testApi(adapter));
    addTearDown(verification.dispose);
    verification.emailChanged('old@example.com');
    await verification.send();
    final confirm = Completer<ResponseBody>();
    adapter.handle = (_) => confirm.future;
    final pending = verification.confirm('012345');
    verification.emailChanged('new@example.com');
    confirm.complete(jsonResponse({'verified': true}, 200));
    expect(await pending, isFalse);
    expect(verification.isVerified, isFalse);
    expect(verification.isCodeSent, isFalse);
  });

  test('중복 클릭·폐기 후 응답은 요청이나 알림을 추가하지 않는다', () async {
    final send = Completer<ResponseBody>();
    final adapter = TestAuthAdapter(handle: (_) => send.future);
    final verification = EmailVerificationViewModel(testApi(adapter));
    var notifications = 0;
    verification.addListener(() => notifications++);
    verification.emailChanged('member@example.com');
    final pending = verification.send();
    expect(await verification.send(), isFalse);
    verification.dispose();
    final before = notifications;
    send.complete(
      jsonResponse({
        'message': 'sent',
        'expiresInSeconds': 300,
        'resendAfterSeconds': 60,
      }, 202),
    );
    expect(await pending, isFalse);
    expect(notifications, before);
    expect(adapter.requests.length, 1);
  });

  test('재설정 토큰은 204 성공·취소·만료 시 제거된다', () async {
    var now = DateTime(2026, 10, 10);
    final adapter = TestAuthAdapter();
    final verification = EmailVerificationViewModel(
      testApi(adapter),
      passwordReset: true,
      now: () => now,
    );
    addTearDown(verification.dispose);
    verification.emailChanged('member@example.com');
    await verification.send();
    expect(await verification.confirm('012345'), isTrue);
    expect(verification.hasResetGrant, isTrue);
    expect(await verification.completeReset('new-password-123'), isTrue);
    expect(verification.hasResetGrant, isFalse);
    now = now.add(const Duration(seconds: 61));
    await verification.send();
    await verification.confirm('012345');
    verification.discardResetGrant();
    expect(verification.hasResetGrant, isFalse);
    now = now.add(const Duration(seconds: 61));
    await verification.send();
    await verification.confirm('012345');
    now = now.add(const Duration(seconds: 601));
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(verification.hasResetGrant, isFalse);
    expect(verification.errorMessage, contains('재설정 시간'));
    final count = adapter.requests.length;
    expect(await verification.completeReset('new-password-123'), isFalse);
    expect(adapter.requests.length, count);
  });

  test('무효 resetToken 오류는 완료 처리 없이 토큰을 제거한다', () async {
    final adapter = TestAuthAdapter();
    final verification = EmailVerificationViewModel(
      testApi(adapter),
      passwordReset: true,
    );
    addTearDown(verification.dispose);
    verification.emailChanged('member@example.com');
    await verification.send();
    await verification.confirm('012345');
    adapter.handle = (_) async =>
        jsonResponse({'code': 'INVALID_RESET_TOKEN'}, 400);
    expect(await verification.completeReset('new-password-123'), isFalse);
    expect(verification.hasResetGrant, isFalse);
  });
}
