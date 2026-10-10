import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_router.dart';
import 'auth_view_model.dart';
import 'auth_validators.dart';
import 'auth_widgets.dart';

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
    if (_isLoading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    final router = GoRouter.of(context);
    final location = router.routeInformationProvider.value.uri;
    var cancelled = false;
    void locationChanged() {
      if (router.routeInformationProvider.value.uri != location) {
        cancelled = true;
      }
    }

    router.routeInformationProvider.addListener(locationChanged);
    final bool succeeded;
    try {
      succeeded = await context.read<AuthViewModel>().login(
        _emailController.text.trim(),
        _passwordController.text,
        isCurrent: () => mounted && !cancelled,
      );
    } finally {
      router.routeInformationProvider.removeListener(locationChanged);
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (succeeded && !cancelled) context.goNamed(AppRouteNames.home);
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
    decorated: true,
    body: LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 700 ||
            MediaQuery.textScalerOf(context).scale(14) >= 21;
        final top = compact ? 16.0 : 40.0;
        return SingleChildScrollView(
          padding: AppSpacing.pagePadding(context, top: top),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - top - 24).clamp(
                0,
                double.infinity,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        AuthBrand(size: compact ? 34 : 48),
                        const SizedBox(height: 16),
                        if (!compact) ...[
                          const AuthIllustration(
                            name: 'login_code',
                            height: 94,
                          ),
                          const SizedBox(height: 24),
                        ],
                        const Text(
                          '다시 만나 반가워요',
                          textAlign: TextAlign.center,
                          style: AppTypography.title,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '로그인하고 학습을 이어가세요',
                          textAlign: TextAlign.center,
                          style: AppTypography.helper,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuthLabeledField(
                              label: '이메일',
                              icon: Icons.mail_outline,
                              child: TextFormField(
                                controller: _emailController,
                                readOnly: _isLoading,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(
                                  hintText: 'example@email.com',
                                ),
                                validator: validateEmail,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AuthLabeledField(
                              label: '비밀번호',
                              icon: Icons.lock_outline,
                              child: TextFormField(
                                controller: _passwordController,
                                readOnly: _isLoading,
                                obscureText: !_isPasswordVisible,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                autofillHints: const [AutofillHints.password],
                                decoration: InputDecoration(
                                  hintText: '비밀번호를 입력해 주세요',
                                  suffixIcon: IconButton(
                                    tooltip: _isPasswordVisible
                                        ? '비밀번호 숨기기'
                                        : '비밀번호 표시',
                                    onPressed: () => setState(
                                      () => _isPasswordVisible =
                                          !_isPasswordVisible,
                                    ),
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? '비밀번호를 입력해 주세요'
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (context.watch<AuthViewModel>().errorMessage
                                case final String message)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Text(
                                  message,
                                  style: AppTypography.helper.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => context.pushNamed(
                                      AppRouteNames.passwordReset,
                                    ),
                              child: const Text('비밀번호 찾기'),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _isLoading ? null : _submit,
                              child: AuthButtonLabel(
                                label: '로그인',
                                isLoading: _isLoading,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () =>
                                        context.pushNamed(AppRouteNames.signUp),
                              child: const Text('회원가입 하기'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Text.rich(
                    TextSpan(
                      text: '오늘의 학습은 ',
                      children: [
                        TextSpan(
                          text: 'COBIA',
                          style: TextStyle(
                            color: authPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(text: '와 함께'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: AppTypography.meta,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
