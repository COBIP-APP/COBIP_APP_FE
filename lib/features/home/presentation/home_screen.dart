import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/router/app_router.dart';
import '../../../app/widgets/app_bottom_navigation.dart';

enum HomeContentState { loading, empty, loaded, error }

// 서버 이력으로 교체할 화면 확인용 데이터입니다. 실제 진행 기록이 아닙니다.
const _sampleLearningStages = ['개념', '예제', '퀴즈'];
const _sampleCompletedStages = 1;

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.initialContentState = HomeContentState.loaded,
  });
  final HomeContentState initialContentState;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeContentState _contentState;

  @override
  void initState() {
    super.initState();
    _contentState = widget.initialContentState;
  }

  Future<void> _retry() async {
    setState(() => _contentState = HomeContentState.loading);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _contentState = HomeContentState.loaded);
  }

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
              child: ListView(
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
                  switch (_contentState) {
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
      _sectionTitle('마지막 학습 이어하기'),
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
            '아직 시작한 학습이 없어요',
            textAlign: TextAlign.center,
            style: AppTypography.section,
          ),
          const SizedBox(height: 8),
          const Text(
            '첫 학습을 시작하고 성장 기록을 만들어 보세요.',
            textAlign: TextAlign.center,
            style: AppTypography.helper,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.pushNamed(AppRouteNames.grammar),
              child: const Text('학습 시작하기'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _loadedContent(BuildContext context) {
    final total = _sampleLearningStages.length;
    final progress = _sampleCompletedStages / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle('마지막 학습 이어하기'),
        Card(
          color: AppColors.primarySoft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.hero),
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.hero),
            onTap: () => context.pushNamed(
              AppRouteNames.grammarExample,
              pathParameters: {'language': 'python'},
            ),
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
                              '예시 · 학습 중',
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
                  const Text(
                    'Python · 조건문',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.card,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '마지막 위치: ${_sampleLearningStages[_sampleCompletedStages]} 1',
                    style: AppTypography.helper,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        '완료 $_sampleCompletedStages / $total 단계',
                        style: AppTypography.helper,
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: AppTypography.link.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    color: AppColors.primary,
                    backgroundColor: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '이어하기 →',
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
        _sectionTitle('학습 추천'),
        _recommendationCard(
          context,
          '문법 학습',
          '조건문 기본 원리',
          '언어별 조건문과 실행 흐름을 배웁니다.',
          Icons.code_rounded,
          AppRouteNames.grammar,
        ),
        _recommendationCard(
          context,
          '실무 학습',
          '실무 기술 학습',
          '캐시, 데이터베이스와 네트워크 개념을 익힙니다.',
          Icons.work_outline,
          AppRouteNames.practical,
        ),
        _recommendationCard(
          context,
          '문제 풀이',
          '문제로 복습하기',
          '학습한 개념을 문제에 적용해 보세요.',
          Icons.quiz_outlined,
          AppRouteNames.problems,
        ),
        const Text('현재 학습 기록은 UI 확인용 예시입니다.', style: AppTypography.meta),
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
          const Text(
            '연결을 확인하고 다시 시도해 주세요.',
            textAlign: TextAlign.center,
            style: AppTypography.helper,
          ),
          const SizedBox(height: 24),
          OutlinedButton(onPressed: _retry, child: const Text('다시 시도')),
        ],
      ),
    ),
  );

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: AppTypography.section),
  );

  Widget _recommendationCard(
    BuildContext context,
    String category,
    String title,
    String description,
    IconData icon,
    String route,
  ) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      borderRadius: BorderRadius.circular(AppRadii.card),
      onTap: () => context.pushNamed(route),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(category, style: AppTypography.meta)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.card,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    description,
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
}
