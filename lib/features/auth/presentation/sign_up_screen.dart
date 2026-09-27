import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import 'auth_validators.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  bool _isCodeSent = false;
  bool _isSendingCode = false;
  bool _isEmailVerified = false;
  bool _isServiceTermsAccepted = false;
  bool _isPrivacyTermsAccepted = false;
  bool _isSubmitting = false;
  bool _isPasswordVisible = false;
  bool _isPasswordConfirmationVisible = false;
  String? _codeError;

  bool get _hasAcceptedAllTerms =>
      _isServiceTermsAccepted && _isPrivacyTermsAccepted;
  bool get _canSubmit =>
      _isEmailVerified &&
      _passwordController.text.isNotEmpty &&
      _passwordController.text == _passwordConfirmationController.text &&
      _hasAcceptedAllTerms &&
      !_isSubmitting;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_emailFieldKey.currentState!.validate()) return;

    setState(() => _isSendingCode = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() {
      _isSendingCode = false;
      _isCodeSent = true;
      _isEmailVerified = false;
      _codeController.clear();
      _codeError = null;
    });
  }

  void _verifyCode() {
    if (!RegExp(r'^\d{6}$').hasMatch(_codeController.text)) {
      setState(() => _codeError = '인증번호 6자리를 입력해 주세요');
      return;
    }
    setState(() {
      _codeError = null;
      _isEmailVerified = true;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_canSubmit) return;

    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    context.goNamed(AppRouteNames.signUpComplete);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'COBIP에서 첫 학습을 시작해 보세요',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: _emailFieldKey,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: '이메일',
                        border: OutlineInputBorder(),
                      ),
                      validator: validateEmail,
                      onChanged: (_) {
                        if (_isCodeSent || _isEmailVerified) {
                          setState(() {
                            _isCodeSent = false;
                            _isEmailVerified = false;
                            _codeController.clear();
                            _codeError = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isEmailVerified || _isSendingCode
                        ? null
                        : _sendCode,
                    child: Text(
                      _isSendingCode
                          ? '요청 중...'
                          : _isCodeSent
                          ? '재전송'
                          : '인증 요청',
                    ),
                  ),
                ],
              ),
              if (_isCodeSent) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('signUpCodeField'),
                        controller: _codeController,
                        enabled: !_isEmailVerified,
                        maxLength: 6,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: '인증번호',
                          errorText: _codeError,
                          helperText: _isEmailVerified
                              ? '이메일 인증이 완료되었습니다.'
                              : '인증번호 6자리를 입력해 주세요.',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) {
                          if (_codeError != null) {
                            setState(() => _codeError = null);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isEmailVerified ? null : _verifyCode,
                      child: const Text('확인'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('signUpPasswordField'),
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _isPasswordVisible ? '비밀번호 숨기기' : '비밀번호 표시',
                    onPressed: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? '비밀번호를 입력해 주세요' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('signUpPasswordConfirmationField'),
                controller: _passwordConfirmationController,
                obscureText: !_isPasswordConfirmationVisible,
                decoration: InputDecoration(
                  labelText: '비밀번호 확인',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _isPasswordConfirmationVisible
                        ? '비밀번호 숨기기'
                        : '비밀번호 표시',
                    onPressed: () => setState(
                      () => _isPasswordConfirmationVisible =
                          !_isPasswordConfirmationVisible,
                    ),
                    icon: Icon(
                      _isPasswordConfirmationVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
                validator: (value) => value != _passwordController.text
                    ? '비밀번호가 일치하지 않습니다'
                    : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                value: _hasAcceptedAllTerms,
                onChanged: (value) => setState(() {
                  _isServiceTermsAccepted = value ?? false;
                  _isPrivacyTermsAccepted = value ?? false;
                }),
                title: const Text('전체 동의'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              _termsTile(
                '서비스 이용약관 동의 (필수)',
                'service',
                _isServiceTermsAccepted,
                (value) =>
                    setState(() => _isServiceTermsAccepted = value ?? false),
              ),
              _termsTile(
                '개인정보 수집 및 이용 동의 (필수)',
                'privacy',
                _isPrivacyTermsAccepted,
                (value) =>
                    setState(() => _isPrivacyTermsAccepted = value ?? false),
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('signUpSubmitButton'),
                onPressed: _canSubmit ? _submit : null,
                child: Text(_isSubmitting ? '가입 중...' : '가입하기'),
              ),
              TextButton(
                onPressed: () => context.goNamed(AppRouteNames.login),
                child: const Text('이미 계정이 있으신가요? 로그인'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _termsTile(
    String label,
    String type,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Expanded(child: Text(label)),
        TextButton(
          onPressed: () => context.pushNamed(
            AppRouteNames.terms,
            pathParameters: {'type': type},
          ),
          child: const Text('보기'),
        ),
      ],
    );
  }
}
