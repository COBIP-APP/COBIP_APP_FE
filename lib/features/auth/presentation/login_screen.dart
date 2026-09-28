import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import 'auth_validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    context.goNamed(AppRouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'COBIP',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      '다시 만나 반가워요',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('로그인하고 학습을 이어가세요'),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: '이메일',
                        hintText: 'example@email.com',
                        border: OutlineInputBorder(),
                      ),
                      validator: validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      autofillHints: const [AutofillHints.password],
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
                      validator: (value) => value == null || value.isEmpty
                          ? '비밀번호를 입력해 주세요'
                          : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            context.pushNamed(AppRouteNames.passwordReset),
                        child: const Text('비밀번호 찾기'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: Text(_isLoading ? '로그인 중...' : '로그인'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('아직 계정이 없으신가요?'),
                        TextButton(
                          onPressed: () =>
                              context.pushNamed(AppRouteNames.signUp),
                          child: const Text('회원가입'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
