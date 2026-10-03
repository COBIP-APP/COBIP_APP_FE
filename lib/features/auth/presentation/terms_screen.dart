import 'package:flutter/material.dart';

import 'auth_widgets.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key, required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final isPrivacy = type == 'privacy';
    final title = isPrivacy ? '개인정보 수집 및 이용 동의' : '서비스 이용약관';
    final sections = isPrivacy
        ? const [
            ('수집 항목', 'COBIA는 회원 식별과 서비스 제공을 위해 이메일 정보를 수집합니다.'),
            ('이용 목적', '수집한 이메일은 회원 식별과 서비스 제공에 사용됩니다.'),
          ]
        : const [
            ('목적', '본 약관은 COBIA 서비스 이용에 필요한 기본 사항을 안내합니다.'),
            ('서비스 이용', '회원은 학습 콘텐츠 조회 등의 서비스를 이용할 수 있습니다.'),
            ('회원의 의무', '타인의 계정을 사용하거나 서비스 운영을 방해하는 행위를 금지합니다.'),
            ('계정 관리', '회원은 자신의 계정 정보를 안전하게 관리해야 합니다.'),
          ];

    return AuthScaffold(
      appBar: AppBar(
        title: const Text('약관 상세'),
        actions: [
          IconButton(
            tooltip: '닫기',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      // 헤더/본문/닫기가 함께 스크롤되어 큰 글씨와 가로 화면에도 잘리지 않습니다.
      body: ListView(
        padding: AppSpacing.pagePadding(context),
        children: [
          Text(title, style: AppTypography.detail),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(AppSpacing.hero),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadii.hero),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) => Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('약관 내용 상세', style: AppTypography.meta),
                        SizedBox(height: 8),
                        Text(
                          '함께 만드는\n더 나은 배움, COBIA',
                          style: AppTypography.section,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '서비스를 시작하기 전 약관을 확인해 주세요.',
                          style: AppTypography.helper,
                        ),
                      ],
                    ),
                  ),
                  if (constraints.maxWidth >= 300 &&
                      MediaQuery.textScalerOf(context).scale(14) < 21) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 110,
                      child: AuthIllustration(name: 'terms_robot', height: 110),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.card),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < sections.length; index++) ...[
                    if (index > 0)
                      const Divider(height: 32, color: AppColors.border),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(
                          '제${index + 1}조',
                          style: AppTypography.meta.copyWith(
                            color: authPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '제${index + 1}조 ${sections[index].$1}',
                      style: AppTypography.card,
                    ),
                    const SizedBox(height: 8),
                    Text(sections[index].$2, style: AppTypography.body),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('닫기'),
          ),
          const SizedBox(height: 8),
          const Text(
            '현재 예시 약관입니다. 실제 약관 원문은 서비스 정책 확정 후 반영됩니다.',
            textAlign: TextAlign.center,
            style: AppTypography.meta,
          ),
        ],
      ),
    );
  }
}
