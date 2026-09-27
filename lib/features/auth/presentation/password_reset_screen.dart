import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import 'auth_validators.dart';

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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
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
    if (!RegExp(r'^\d{6}$').hasMatch(_codeController.text)) {
      setState(() => _codeError = '인증번호 6자리를 입력해 주세요');
      return;
    }
    setState(() {
      _codeError = null;
      _step = _PasswordResetStep.newPassword;
    });
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate() || !_canSavePassword) return;

    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    context.goNamed(AppRouteNames.passwordResetComplete);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(switch (_step) {
          _PasswordResetStep.email => '비밀번호 찾기',
          _PasswordResetStep.verification => '계정 복구 인증',
          _PasswordResetStep.newPassword => '새 비밀번호 설정',
        }),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: switch (_step) {
              _PasswordResetStep.email => _emailStep(context),
              _PasswordResetStep.verification => _verificationStep(context),
              _PasswordResetStep.newPassword => _newPasswordStep(context),
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _emailStep(BuildContext context) => [
    Text(
      '가입한 이메일을 입력해 주세요',
      style: Theme.of(context).textTheme.headlineSmall
          ?.copyWith(fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 8),
    const Text('비밀번호를 다시 설정할 수 있도록 인증번호를 보내드려요.'),
    const SizedBox(height: 32),
    TextFormField(
      key: const Key('resetEmailField'),
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: '이메일',
        hintText: 'example@email.com',
        border: OutlineInputBorder(),
      ),
      validator: validateEmail,
    ),
    const SizedBox(height: 24),
    FilledButton(
      onPressed: _isLoading ? null : _sendCode,
      child: Text(_isLoading ? '요청 중...' : '인증번호 받기'),
    ),
    TextButton(
      onPressed: () => context.goNamed(AppRouteNames.login),
      child: const Text('로그인으로 돌아가기'),
    ),
  ];

  List<Widget> _verificationStep(BuildContext context) => [
    Text(
      '이메일 인증',
      style: Theme.of(context).textTheme.headlineSmall
          ?.copyWith(fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 8),
    Text('${_emailController.text}로 보낸 인증번호를 입력해 주세요.'),
    const SizedBox(height: 32),
    TextField(
      key: const Key('resetCodeField'),
      controller: _codeController,
      keyboardType: TextInputType.number,
      maxLength: 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: '인증번호',
        errorText: _codeError,
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) {
        if (_codeError != null) setState(() => _codeError = null);
      },
    ),
    const SizedBox(height: 8),
    FilledButton(onPressed: _verifyCode, child: const Text('인증 확인')),
    TextButton(
      onPressed: _isLoading ? null : _sendCode,
      child: Text(_isLoading ? '재전송 중...' : '인증번호 재전송'),
    ),
  ];

  List<Widget> _newPasswordStep(BuildContext context) => [
    Text(
      '새 비밀번호를 설정해 주세요',
      style: Theme.of(context).textTheme.headlineSmall
          ?.copyWith(fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 32),
    _passwordField(
      controller: _passwordController,
      label: '새 비밀번호',
      isVisible: _isPasswordVisible,
      onVisibilityChanged: () =>
          setState(() => _isPasswordVisible = !_isPasswordVisible),
      validator: (value) =>
          value == null || value.isEmpty ? '새 비밀번호를 입력해 주세요' : null,
    ),
    const SizedBox(height: 16),
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
    const SizedBox(height: 24),
    FilledButton(
      onPressed: _canSavePassword ? _savePassword : null,
      child: Text(_isLoading ? '변경 중...' : '비밀번호 변경'),
    ),
  ];

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onVisibilityChanged,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: isVisible ? '비밀번호 숨기기' : '비밀번호 표시',
          onPressed: onVisibilityChanged,
          icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility),
        ),
      ),
      validator: validator,
      onChanged: (_) => setState(() {}),
    );
  }
}
