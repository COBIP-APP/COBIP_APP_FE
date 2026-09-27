import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final isPrivacy = type == 'privacy';
    final title = isPrivacy ? '개인정보 수집 및 이용 동의' : '서비스 이용약관';
    final body = isPrivacy
        ? 'COBIP은 회원 식별과 서비스 제공을 위해 이메일 정보를 수집합니다. 실제 약관 원문은 서비스 정책 확정 후 반영됩니다.'
        : 'COBIP 서비스 이용에 필요한 기본 약관입니다. 실제 약관 원문은 서비스 정책 확정 후 반영됩니다.';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Text(body, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ),
    );
  }
}
