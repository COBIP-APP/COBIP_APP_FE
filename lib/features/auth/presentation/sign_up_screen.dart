import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_router.dart';
import '../data/auth_api.dart';
import 'auth_validators.dart';
import 'auth_view_model.dart';
import 'auth_widgets.dart';
import 'email_verification_view_model.dart';

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
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  late final EmailVerificationViewModel _verification;
  bool get _isCodeSent => _verification.isCodeSent;
  bool get _isSendingCode => _verification.isSending;
  bool get _isEmailVerified => _verification.isVerified;
  bool _isServiceTermsAccepted = false;
  bool _isPrivacyTermsAccepted = false;
  bool _isSubmitting = false;
  bool _isPasswordVisible = false;
  bool _isPasswordConfirmationVisible = false;
  String? _errorMessage;
  Map<String, String> _fieldErrors = {};

  bool get _hasAcceptedAllTerms =>
      _isServiceTermsAccepted && _isPrivacyTermsAccepted;
  bool get _canSubmit =>
      _isEmailVerified &&
      validateEmail(_emailController.text) == null &&
      validateNickname(_nicknameController.text) == null &&
      validatePassword(_passwordController.text) == null &&
      _passwordController.text == _passwordConfirmationController.text &&
      _hasAcceptedAllTerms &&
      !_isSubmitting &&
      !_verification.isBusy;

  @override
  void initState() {
    super.initState();
    _verification = EmailVerificationViewModel(
      context.read<AuthViewModel>().api,
      now: context.read<AuthViewModel>().now,
    );
    _verification.addListener(_verificationChanged);
  }

  void _verificationChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _verification.dispose();
    _emailController.dispose();
    _codeController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_isSubmitting ||
        !_emailFieldKey.currentState!.validate() ||
        !_verification.canSend) {
      return;
    }
    _codeController.clear();
    await _verification.send();
  }

  Future<void> _verifyCode() async {
    if (_isSubmitting) return;
    if (await _verification.confirm(_codeController.text) && mounted) {
      _codeController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final router = GoRouter.of(context);
    final location = router.routeInformationProvider.value.uri;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _fieldErrors = {};
    });
    try {
      await context.read<AuthViewModel>().api.register(
        email: _emailController.text.trim(),
        nickname: _nicknameController.text.trim(),
        password: _passwordController.text,
        serviceTermsAgreed: _isServiceTermsAccepted,
        privacyTermsAgreed: _isPrivacyTermsAccepted,
      );
      if (mounted && router.routeInformationProvider.value.uri == location) {
        context.goNamed(AppRouteNames.signUpComplete);
      }
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _fieldErrors = {...error.fieldErrors};
        if (error.code == 'NICKNAME_ALREADY_USED') {
          _fieldErrors['nickname'] = error.message;
        }
        if (error.code == 'EMAIL_ALREADY_USED') {
          _fieldErrors['email'] = error.message;
        }
      });
      if (error.code == 'EMAIL_NOT_VERIFIED') {
        _verification.revokeVerification();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = '가입 결과를 확인하지 못했습니다. 다시 시도하거나 로그인해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
                readOnly: _isSubmitting,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  hintText: 'example@email.com',
                  errorText: _fieldErrors['email'],
                ),
                validator: validateEmail,
                onChanged: (value) {
                  _codeController.clear();
                  _verification.emailChanged(value);
                  setState(() => _fieldErrors.remove('email'));
                },
              ),
              action: OutlinedButton(
                onPressed: !_verification.canSend || _isSubmitting
                    ? null
                    : _sendCode,
                child: AuthButtonLabel(
                  label: _verification.resendSeconds > 0
                      ? '${_verification.resendSeconds}초 후 재전송'
                      : _isCodeSent
                      ? '재전송'
                      : '인증 요청',
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
                enabled: _verification.canConfirm && !_isSubmitting,
                maxLength: 6,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _verifyCode(),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '인증번호 6자리',
                  errorText: _verification.codeError,
                  counterText: '',
                ),
              ),
              action: OutlinedButton(
                onPressed: _verification.canConfirm && !_isSubmitting
                    ? _verifyCode
                    : null,
                child: AuthButtonLabel(
                  label: _isEmailVerified ? '인증 완료' : '확인',
                  isLoading: _verification.isConfirming,
                ),
              ),
            ),
          ),
          if (_verification.isCodeSent)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '인증번호 유효시간 ${_verification.codeSeconds}초',
                style: AppTypography.helper,
              ),
            ),
          if (_verification.errorMessage case final String message)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                message,
                style: AppTypography.helper.copyWith(color: AppColors.error),
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
            label: '닉네임',
            child: TextFormField(
              key: const Key('signUpNicknameField'),
              controller: _nicknameController,
              readOnly: _isSubmitting,
              textInputAction: TextInputAction.next,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                hintText: '닉네임을 입력해 주세요',
                helperText: '앞뒤 공백 제외 2~50자',
                errorText: _fieldErrors['nickname'],
              ),
              validator: validateNickname,
              onChanged: (_) => setState(() {
                _fieldErrors.remove('nickname');
                _errorMessage = null;
              }),
            ),
          ),
          const SizedBox(height: 16),
          AuthLabeledField(
            label: '비밀번호',
            child: TextFormField(
              key: const Key('signUpPasswordField'),
              controller: _passwordController,
              readOnly: _isSubmitting,
              obscureText: !_isPasswordVisible,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                hintText: '비밀번호를 입력해 주세요',
                helperText: '8~64자',
                errorText: _fieldErrors['password'],
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
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: validatePassword,
              onChanged: (_) => setState(() => _fieldErrors.remove('password')),
            ),
          ),
          const SizedBox(height: 16),
          AuthLabeledField(
            label: '비밀번호 확인',
            child: TextFormField(
              key: const Key('signUpPasswordConfirmationField'),
              controller: _passwordConfirmationController,
              readOnly: _isSubmitting,
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
                    onChanged: _isSubmitting
                        ? null
                        : (value) => setState(() {
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
          if (_errorMessage case final String message)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                message,
                style: AppTypography.helper.copyWith(color: AppColors.error),
              ),
            ),
          FilledButton(
            key: const Key('signUpSubmitButton'),
            onPressed: _canSubmit ? _submit : null,
            child: AuthButtonLabel(label: '가입하기', isLoading: _isSubmitting),
          ),
          TextButton(
            onPressed: _isSubmitting
                ? null
                : () => context.goNamed(AppRouteNames.login),
            child: const Text('이미 계정이 있으신가요? 로그인'),
          ),
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
      Checkbox(value: value, onChanged: _isSubmitting ? null : onChanged),
      Expanded(
        child: Text(
          label,
          style: AppTypography.helper.copyWith(color: AppColors.textPrimary),
        ),
      ),
      TextButton(
        onPressed: _isSubmitting
            ? null
            : () => context.pushNamed(
                AppRouteNames.terms,
                pathParameters: {'type': type},
              ),
        child: const Text('보기'),
      ),
    ],
  );
}
