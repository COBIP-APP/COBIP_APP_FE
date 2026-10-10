import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_router.dart';
import 'auth_validators.dart';
import 'auth_view_model.dart';
import 'auth_widgets.dart';
import 'email_verification_view_model.dart';

enum _PasswordResetStep { email, verification, newPassword }

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  _PasswordResetStep _step = _PasswordResetStep.email;
  late final EmailVerificationViewModel _verification;
  bool get _isLoading => _verification.isBusy;
  bool _isSaving = false;
  bool _isPasswordVisible = false;
  bool _isPasswordConfirmationVisible = false;

  bool get _canSavePassword =>
      validatePassword(_passwordController.text) == null &&
      _passwordController.text == _passwordConfirmationController.text &&
      _verification.hasResetGrant &&
      !_isLoading;

  @override
  void initState() {
    super.initState();
    _verification = EmailVerificationViewModel(
      context.read<AuthViewModel>().api,
      passwordReset: true,
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
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_isLoading ||
        !_formKey.currentState!.validate() ||
        !_verification.canSend) {
      return;
    }
    _codeController.clear();
    if (await _verification.send() && mounted) {
      setState(() => _step = _PasswordResetStep.verification);
    }
  }

  Future<void> _verifyCode() async {
    if (_step != _PasswordResetStep.verification || _isLoading) return;
    if (await _verification.confirm(_codeController.text) && mounted) {
      _codeController.clear();
      setState(() => _step = _PasswordResetStep.newPassword);
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _savePassword() async {
    if (!_canSavePassword || !_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final router = GoRouter.of(context);
    final location = router.routeInformationProvider.value.uri;
    final auth = context.read<AuthViewModel>();
    final succeeded = await _verification.completeReset(
      _passwordController.text,
    );
    if (succeeded) await auth.clearSession();
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (succeeded && router.routeInformationProvider.value.uri == location) {
      context.goNamed(AppRouteNames.passwordResetComplete);
    }
  }

  void _goBack() {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();
    _verification.discardResetGrant();
    if (_step == _PasswordResetStep.newPassword) {
      setState(() {
        _step = _PasswordResetStep.verification;
        _codeController.clear();
        _passwordController.clear();
        _passwordConfirmationController.clear();
      });
    } else {
      context.goNamed(AppRouteNames.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: AuthScaffold(
        appBar: AppBar(
          title: const Text('비밀번호 찾기'),
          leading: BackButton(onPressed: _goBack),
        ),
        decorated: _step == _PasswordResetStep.newPassword,
        body: Form(
          key: _formKey,
          child: ListView(
            key: ValueKey(_step == _PasswordResetStep.newPassword),
            padding: AppSpacing.pagePadding(context),
            children: _step == _PasswordResetStep.newPassword
                ? _newPasswordStep(context)
                : _recoveryStep(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _recoveryStep(BuildContext context) => [
    const AuthBrand(size: 28),
    const SizedBox(height: 16),
    AuthIllustration(
      name: 'password_email',
      height: MediaQuery.viewInsetsOf(context).bottom > 0 ? 64 : 132,
    ),
    const SizedBox(height: 24),
    const Text(
      '비밀번호 찾기',
      textAlign: TextAlign.center,
      style: AppTypography.title,
    ),
    const SizedBox(height: 8),
    const Text(
      '가입한 이메일을 입력해 주세요',
      textAlign: TextAlign.center,
      style: AppTypography.helper,
    ),
    const SizedBox(height: 32),
    AuthLabeledField(
      label: '이메일',
      child: AuthFieldAction(
        field: TextFormField(
          key: const Key('resetEmailField'),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          readOnly: _isSaving,
          decoration: const InputDecoration(hintText: 'example@email.com'),
          validator: validateEmail,
          onChanged: (value) {
            _verification.emailChanged(value);
            if (_step == _PasswordResetStep.verification) {
              setState(() {
                _step = _PasswordResetStep.email;
                _codeController.clear();
              });
            }
          },
        ),
        action: OutlinedButton(
          onPressed: _verification.canSend ? _sendCode : null,
          child: AuthButtonLabel(
            label: _verification.resendSeconds > 0
                ? '${_verification.resendSeconds}초 후 재전송'
                : _step == _PasswordResetStep.verification
                ? '재전송'
                : '인증번호 받기',
            isLoading: _verification.isSending,
          ),
        ),
      ),
    ),
    const SizedBox(height: 8),
    const Text('가입된 이메일이라면 인증번호가 발송됩니다.', style: AppTypography.helper),
    const SizedBox(height: 32),
    AuthLabeledField(
      label: '인증번호',
      child: TextField(
        key: const Key('resetCodeField'),
        controller: _codeController,
        enabled: _verification.canConfirm,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _verifyCode(),
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          hintText: '인증번호 6자리',
          errorText: _verification.codeError,
          counterText: '',
        ),
      ),
    ),
    const SizedBox(height: 8),
    Text(
      _verification.isCodeSent
          ? '인증번호 유효시간 ${_verification.codeSeconds}초'
          : '인증번호를 입력하고 확인해 주세요.',
      style: AppTypography.helper,
    ),
    if (_verification.errorMessage case final String message)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          message,
          style: AppTypography.helper.copyWith(color: AppColors.error),
        ),
      ),
    const SizedBox(height: 32),
    FilledButton(
      onPressed: _verification.canConfirm ? _verifyCode : null,
      child: AuthButtonLabel(
        label: '인증 확인',
        isLoading: _verification.isConfirming,
      ),
    ),
    const SizedBox(height: 16),
    TextButton(
      onPressed: _isSaving ? null : () => context.goNamed(AppRouteNames.login),
      child: const Text('로그인으로 돌아가기'),
    ),
  ];

  List<Widget> _newPasswordStep(BuildContext context) => [
    const AuthBrand(size: 28),
    const SizedBox(height: 16),
    AuthIllustration(
      name: 'password_lock',
      height: MediaQuery.viewInsetsOf(context).bottom > 0 ? 64 : 132,
    ),
    const SizedBox(height: 24),
    const Text(
      '새 비밀번호 설정',
      textAlign: TextAlign.center,
      style: AppTypography.title,
    ),
    const SizedBox(height: 8),
    const Text(
      '새 비밀번호를 설정해 주세요',
      textAlign: TextAlign.center,
      style: AppTypography.helper,
    ),
    const SizedBox(height: 40),
    _passwordField(
      controller: _passwordController,
      label: '새 비밀번호',
      isVisible: _isPasswordVisible,
      onVisibilityChanged: () =>
          setState(() => _isPasswordVisible = !_isPasswordVisible),
      validator: validatePassword,
    ),
    const SizedBox(height: 24),
    _passwordField(
      controller: _passwordConfirmationController,
      label: '새 비밀번호 확인',
      isVisible: _isPasswordConfirmationVisible,
      onVisibilityChanged: () => setState(
        () => _isPasswordConfirmationVisible = !_isPasswordConfirmationVisible,
      ),
      validator: (value) =>
          value != _passwordController.text ? '비밀번호가 일치하지 않습니다' : null,
    ),
    if (_canSavePassword)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: authSuccess, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '비밀번호가 일치합니다',
                style: AppTypography.helper.copyWith(color: authSuccess),
              ),
            ),
          ],
        ),
      ),
    const SizedBox(height: 40),
    if (_verification.errorMessage case final String message)
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          message,
          style: AppTypography.helper.copyWith(color: AppColors.error),
        ),
      ),
    FilledButton(
      onPressed: _canSavePassword ? _savePassword : null,
      child: AuthButtonLabel(label: '비밀번호 변경', isLoading: _isLoading),
    ),
    const SizedBox(height: 16),
    const Text(
      '변경 후 새 비밀번호로 로그인해 주세요.',
      textAlign: TextAlign.center,
      style: AppTypography.helper,
    ),
    if (!_verification.hasResetGrant)
      TextButton(onPressed: _goBack, child: const Text('인증번호 다시 요청')),
  ];

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onVisibilityChanged,
    required String? Function(String?) validator,
  }) {
    return AuthLabeledField(
      label: label,
      child: TextFormField(
        key: Key(
          controller == _passwordController
              ? 'newPasswordField'
              : 'newPasswordConfirmationField',
        ),
        controller: controller,
        readOnly: _isLoading,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        obscureText: !isVisible,
        textInputAction: controller == _passwordController
            ? TextInputAction.next
            : TextInputAction.done,
        autofillHints: const [AutofillHints.newPassword],
        onFieldSubmitted: (_) {
          if (controller == _passwordConfirmationController &&
              _canSavePassword) {
            _savePassword();
          }
        },
        decoration: InputDecoration(
          hintText: label,
          helperText: controller == _passwordController ? '8~64자' : null,
          errorText:
              controller == _passwordConfirmationController &&
                  controller.text.isNotEmpty &&
                  controller.text != _passwordController.text
              ? '비밀번호가 일치하지 않습니다'
              : null,
          suffixIcon: IconButton(
            tooltip: isVisible ? '비밀번호 숨기기' : '비밀번호 표시',
            onPressed: onVisibilityChanged,
            icon: Icon(
              isVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
        ),
        validator: validator,
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}
