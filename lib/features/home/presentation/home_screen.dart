import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/router/app_router.dart';
import '../../../app/widgets/app_bottom_navigation.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../data/home_api.dart';
import 'home_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.select<AuthViewModel, int?>(
      (auth) => auth.user?.userId,
    );
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('로그인이 필요합니다.')));
    }
    return ChangeNotifierProvider(
      key: ValueKey(userId),
      create: (context) => HomeViewModel(
        api: HomeApi(context.read<AuthViewModel>().api.dio),
        userId: userId,
      )..load(),
      child: const _HomeContent(),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) => Theme(
    data: appUiTheme,
    child: Builder(
      builder: (context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.contentWidth + 40,
              ),
              child: RefreshIndicator(
                onRefresh: context.read<HomeViewModel>().load,
                child: ListView(
                  key: const Key('homeContentList'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppSpacing.pagePadding(context, top: 4),
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 48),
                        const Expanded(
                          child: Text(
                            'COBIA',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: '프로필',
                          onPressed: () =>
                              context.pushNamed(AppRouteNames.myPage),
                          icon: const Icon(
                            Icons.person_outline,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _hero(context),
                    const SizedBox(height: AppSpacing.section),
                    switch (context.watch<HomeViewModel>().state) {
                      HomeContentState.loading => _loadingContent(context),
                      HomeContentState.empty => _emptyContent(context),
                      HomeContentState.loaded => _loadedContent(context),
                      HomeContentState.error => _errorContent(context),
                    },
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: AppBottomNavigation(selectedIndex: 0),
      ),
    ),
  );

  Widget _hero(BuildContext context) {
    const greeting = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: '오늘도\n',
            children: [
              TextSpan(
                text: '한 단계 성장해 볼까요?',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
          style: AppTypography.section,
        ),
        SizedBox(height: 12),
        Text('작은 학습이 큰 변화를 만듭니다.', style: AppTypography.helper),
      ],
    );
    final illustration = Image.asset(
      'assets/images/auth/home_learning.png',
      width: 110,
      height: 110,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => const ExcludeSemantics(
        child: SizedBox(
          width: 110,
          height: 110,
          child: Icon(
            Icons.school_outlined,
            size: 48,
            color: AppColors.primary,
          ),
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(14) >= 21) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              greeting,
              Align(alignment: Alignment.centerRight, child: illustration),
            ],
          );
        }
        return Row(
          children: [
            const Expanded(child: greeting),
            const SizedBox(width: 12),
            illustration,
          ],
        );
      },
    );
  }

  Widget _loadingContent(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _sectionTitle('마지막 학습'),
      Semantics(
        label: '학습 정보 불러오는 중',
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadii.hero),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.section),
      _sectionTitle('학습 추천'),
      for (var index = 0; index < 3; index++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 104,
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
          ),
        ),
    ],
  );

  Widget _emptyContent(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.hero),
      child: Column(
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            '등록된 학습이 없어요',
            textAlign: TextAlign.center,
            style: AppTypography.section,
          ),
          const SizedBox(height: 8),
          const Text(
            '학습 콘텐츠가 등록되면 이곳에서 확인할 수 있어요.',
            textAlign: TextAlign.center,
            style: AppTypography.helper,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: context.read<HomeViewModel>().load,
              child: const Text('새로고침'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _loadedContent(BuildContext context) {
    final home = context.watch<HomeViewModel>();
    final template = home.latestTemplate;
    final progress = home.latestProgress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle('마지막 학습'),
        if (template == null || progress == null)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.hero),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('아직 시작한 학습이 없어요', style: AppTypography.card),
                  SizedBox(height: 8),
                  Text('아래에서 등록된 학습을 확인해 보세요.', style: AppTypography.helper),
                ],
              ),
            ),
          )
        else
          Card(
            color: AppColors.primarySoft,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.hero),
              side: const BorderSide(color: AppColors.border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.hero),
              onTap: () => _showDetailPending(context),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.hero),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.pill,
                                ),
                              ),
                              child: Text(
                                progress.completedAt == null ? '학습 중' : '학습 완료',
                                style: AppTypography.meta.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.play_circle_outline,
                          size: 24,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      template.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.card,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      progress.lastSectionId == null
                          ? '마지막 위치 정보가 없어요'
                          : '마지막 위치: 섹션 ${progress.lastSectionId}',
                      style: AppTypography.helper,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '마지막 학습: ${_studyDate(progress.lastStudiedAt)}',
                      style: AppTypography.helper,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '학습 상세 연결 준비 중',
                      style: AppTypography.link.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.section),
        const Text('현재 공개된 학습의 기록입니다.', style: AppTypography.meta),
        const SizedBox(height: 12),
        _sectionTitle('학습 추천'),
        for (final item in home.templates) _recommendationCard(context, item),
        const Text('공개 학습 목록을 서버 표시 순서로 안내합니다.', style: AppTypography.meta),
      ],
    );
  }

  Widget _errorContent(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.hero),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          const Text(
            '학습 정보를 불러오지 못했어요',
            textAlign: TextAlign.center,
            style: AppTypography.section,
          ),
          const SizedBox(height: 8),
          Text(
            context.watch<HomeViewModel>().errorMessage ??
                '연결을 확인하고 다시 시도해 주세요.',
            textAlign: TextAlign.center,
            style: AppTypography.helper,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: context.read<HomeViewModel>().load,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    ),
  );

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: AppTypography.section),
  );

  Widget _recommendationCard(BuildContext context, HomeTemplate template) =>
      Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.card),
          onTap: () => _showDetailPending(context),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.card),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.menu_book_outlined,
                      size: 24,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        [
                          template.categoryName,
                          template.languageName,
                        ].whereType<String>().join(' · '),
                        style: AppTypography.meta,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  template.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.card,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        template.summary ?? '설명이 등록되지 않았어요.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.helper,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      size: 24,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  void _showDetailPending(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('학습 상세 화면의 서버 연동은 준비 중입니다.')));
  }

  String _studyDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}.${local.month.toString().padLeft(2, '0')}.'
        '${local.day.toString().padLeft(2, '0')}';
  }
}
