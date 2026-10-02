import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import 'auth_validators.dart';
import 'auth_widgets.dart';

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
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isPasswordConfirmationVisible = false;
  String? _codeError;

  bool get _canSavePassword =>
      _passwordController.text.isNotEmpty &&
      _passwordController.text == _passwordConfirmationController.text &&
      !_isLoading;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _step = _PasswordResetStep.email;
      _codeController.clear();
    });
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _step = _PasswordResetStep.verification;
      _codeController.clear();
      _codeError = null;
    });
  }

  void _verifyCode() {
    if (_step != _PasswordResetStep.verification || _isLoading) return;
    if (!RegExp(r'^\d{6}$').hasMatch(_codeController.text)) {
      setState(() => _codeError = '인증번호 6자리를 입력해 주세요');
      return;
    }
    setState(() {
      _codeError = null;
      _step = _PasswordResetStep.newPassword;
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _savePassword() async {
    if (!_canSavePassword || !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    context.goNamed(AppRouteNames.passwordResetComplete);
  }

  void _goBack() {
    FocusScope.of(context).unfocus();
    if (_step == _PasswordResetStep.newPassword) {
      setState(() {
        _step = _PasswordResetStep.verification;
        _codeController.clear();
        _codeError = null;
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
          readOnly: _isLoading,
          decoration: const InputDecoration(hintText: 'example@email.com'),
          validator: validateEmail,
          onChanged: (_) {
            if (_step == _PasswordResetStep.verification) {
              setState(() {
                _step = _PasswordResetStep.email;
                _codeController.clear();
                _codeError = null;
              });
            }
          },
        ),
        action: OutlinedButton(
          onPressed: _isLoading ? null : _sendCode,
          child: AuthButtonLabel(
            label: _step == _PasswordResetStep.verification ? '재전송' : '인증번호 받기',
            isLoading: _isLoading,
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
        enabled: _step == _PasswordResetStep.verification && !_isLoading,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _verifyCode(),
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          hintText: '인증번호 6자리',
          errorText: _codeError,
          counterText: '',
        ),
        onChanged: (_) {
          setState(() => _codeError = null);
        },
      ),
    ),
    const SizedBox(height: 8),
    const Text('인증번호를 입력하고 확인해 주세요.', style: AppTypography.helper),
    const SizedBox(height: 32),
    FilledButton(
      onPressed: _step == _PasswordResetStep.verification && !_isLoading
          ? _verifyCode
          : null,
      child: const Text('인증 확인'),
    ),
    const SizedBox(height: 16),
    TextButton(
      onPressed: () => context.goNamed(AppRouteNames.login),
      child: const Text('로그인으로 돌아가기'),
    ),
    const AuthPreviewNotice(),
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
      validator: (value) =>
          value == null || value.isEmpty ? '새 비밀번호를 입력해 주세요' : null,
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
    const AuthPreviewNotice(),
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
