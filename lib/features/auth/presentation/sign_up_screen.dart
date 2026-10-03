import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import 'auth_validators.dart';
import 'auth_widgets.dart';

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
    if (_isSendingCode ||
        _isEmailVerified ||
        !_emailFieldKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSendingCode = true;
      _isCodeSent = false;
      _codeController.clear();
      _codeError = null;
    });
    // UI 미리보기입니다. 인증 시각/코드 판정/저장은 서버 계약 확정 후 연결합니다.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() {
      _isSendingCode = false;
      _isCodeSent = true;
    });
  }

  void _verifyCode() {
    if (!_isCodeSent || _isSendingCode || _isEmailVerified) return;
    if (!RegExp(r'^\d{6}$').hasMatch(_codeController.text)) {
      setState(() => _codeError = '인증번호 6자리를 입력해 주세요');
      return;
    }
    setState(() {
      _codeError = null;
      _isEmailVerified = true;
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _submit() async {
    if (!_canSubmit || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    context.goNamed(AppRouteNames.signUpComplete);
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
    appBar: AppBar(title: const AuthBrand(size: 24)),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: AppSpacing.pagePadding(context, top: 8),
        children: [
          Text(
            '회원가입',
            textAlign: TextAlign.center,
            style: AppTypography.title.copyWith(color: authPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'COBIA에서 첫 학습을 시작해 보세요',
            textAlign: TextAlign.center,
            style: AppTypography.helper,
          ),
          const SizedBox(height: 24),
          AuthLabeledField(
            label: '이메일',
            child: AuthFieldAction(
              field: TextFormField(
                key: _emailFieldKey,
                controller: _emailController,
                readOnly: _isSendingCode || _isSubmitting,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  hintText: 'example@email.com',
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
              action: OutlinedButton(
                onPressed: _isEmailVerified || _isSendingCode || _isSubmitting
                    ? null
                    : _sendCode,
                child: AuthButtonLabel(
                  label: _isCodeSent ? '재전송' : '인증 요청',
                  isLoading: _isSendingCode,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AuthLabeledField(
            label: '이메일 인증번호',
            child: AuthFieldAction(
              field: TextField(
                key: const Key('signUpCodeField'),
                controller: _codeController,
                enabled: _isCodeSent && !_isEmailVerified && !_isSendingCode,
                maxLength: 6,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _verifyCode(),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '인증번호 6자리',
                  errorText: _codeError,
                  counterText: '',
                ),
                onChanged: (_) {
                  if (_codeError != null) setState(() => _codeError = null);
                },
              ),
              action: OutlinedButton(
                onPressed: _isCodeSent && !_isEmailVerified && !_isSendingCode
                    ? _verifyCode
                    : null,
                child: Text(_isEmailVerified ? '인증 완료' : '확인'),
              ),
            ),
          ),
          if (_isEmailVerified)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: authSuccess, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '이메일 인증이 완료되었습니다.',
                      style: AppTypography.helper.copyWith(color: authSuccess),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          AuthLabeledField(
            label: '비밀번호',
            child: TextFormField(
              key: const Key('signUpPasswordField'),
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                hintText: '비밀번호를 입력해 주세요',
                suffixIcon: IconButton(
                  tooltip: _isPasswordVisible ? '비밀번호 숨기기' : '비밀번호 표시',
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? '비밀번호를 입력해 주세요' : null,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 16),
          AuthLabeledField(
            label: '비밀번호 확인',
            child: TextFormField(
              key: const Key('signUpPasswordConfirmationField'),
              controller: _passwordConfirmationController,
              obscureText: !_isPasswordConfirmationVisible,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                hintText: '비밀번호를 한 번 더 입력해 주세요',
                errorText:
                    _passwordConfirmationController.text.isNotEmpty &&
                        _passwordConfirmationController.text !=
                            _passwordController.text
                    ? '비밀번호가 일치하지 않습니다'
                    : null,
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
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator: (value) =>
                  value != _passwordController.text ? '비밀번호가 일치하지 않습니다' : null,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 24),
          Material(
            color: authInputFill,
            borderRadius: BorderRadius.circular(AppRadii.card),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _hasAcceptedAllTerms,
                    onChanged: (value) => setState(() {
                      _isServiceTermsAccepted = value ?? false;
                      _isPrivacyTermsAccepted = value ?? false;
                    }),
                    title: const Text('전체 동의', style: AppTypography.card),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  _termsTile(
                    '(필수) 서비스 이용약관 동의',
                    'service',
                    _isServiceTermsAccepted,
                    (value) => setState(
                      () => _isServiceTermsAccepted = value ?? false,
                    ),
                  ),
                  _termsTile(
                    '(필수) 개인정보 수집 및 이용 동의',
                    'privacy',
                    _isPrivacyTermsAccepted,
                    (value) => setState(
                      () => _isPrivacyTermsAccepted = value ?? false,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('signUpSubmitButton'),
            onPressed: _canSubmit ? _submit : null,
            child: AuthButtonLabel(label: '가입하기', isLoading: _isSubmitting),
          ),
          TextButton(
            onPressed: () => context.goNamed(AppRouteNames.login),
            child: const Text('이미 계정이 있으신가요? 로그인'),
          ),
          const AuthPreviewNotice(),
        ],
      ),
    ),
  );

  Widget _termsTile(
    String label,
    String type,
    bool value,
    ValueChanged<bool?> onChanged,
  ) => Row(
    children: [
      Checkbox(value: value, onChanged: onChanged),
      Expanded(
        child: Text(
          label,
          style: AppTypography.helper.copyWith(color: AppColors.textPrimary),
        ),
      ),
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
