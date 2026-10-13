import '../../../app/widgets/progressive_card_list.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/router/app_router.dart';
import '../../../app/widgets/learning_card.dart';
import '../../../app/widgets/learning_ui.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../../learning/presentation/learning_store.dart';
import '../../learning/presentation/learning_preview_widgets.dart';
import '../data/my_page_api.dart';
import 'my_page_view_model.dart';
import 'question_delete_button.dart';

enum _Tab {
  learning('내 학습'),
  bookmarks('북마크'),
  results('최근 결과'),
  generated('AI 생성 문제');

  const _Tab(this.label);
  final String label;
}

enum _LearningFilter {
  all('전체 보기'),
  inProgress('학습 중'),
  completed('학습 완료');

  const _LearningFilter(this.label);
  final String label;
}

String _date(DateTime value) {
  final date = value.toLocal();
  return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
}

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final userId = auth.user?.userId;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('로그인이 필요합니다.')));
    }
    return ChangeNotifierProvider(
      key: ValueKey(userId),
      create: (_) =>
          MyPageViewModel(api: MyPageApi(auth.api.dio), userId: userId)
            ..refresh(),
      child: const _MyPageBody(),
    );
  }
}

class _MyPageBody extends StatefulWidget {
  const _MyPageBody();
  @override
  State<_MyPageBody> createState() => _MyPageBodyState();
}

class _MyPageBodyState extends State<_MyPageBody> {
  _Tab _tab = _Tab.learning;
  _LearningFilter _learningFilter = _LearningFilter.all;

  Future<void> _refresh() async {
    await Future.wait([
      context.read<MyPageViewModel>().refresh(),
      if (_tab == _Tab.generated)
        context.read<LearningStore>().loadMyQuestions(),
    ]);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openTemplate(int id, [int? sectionId]) async {
    final vm = context.read<MyPageViewModel>();
    try {
      final destination = await vm.destination(id, sectionId);
      if (!mounted || destination == null) return;
      await context.pushNamed(
        destination.grammar
            ? AppRouteNames.grammarConcept
            : AppRouteNames.practicalChapter,
        pathParameters: {
          'template': '${destination.templateId}',
          if (destination.grammar)
            'language': destination.language
          else
            'topic': '${destination.categoryId}',
        },
        queryParameters: {
          if (destination.sectionId != null)
            'section': '${destination.sectionId}',
        },
      );
      if (mounted && !vm.disposed) await vm.refresh();
    } catch (error) {
      if (!vm.disposed) _showError(vm.message(error));
    }
  }

  Future<void> _removeBookmark(MyBookmark item) async {
    final vm = context.read<MyPageViewModel>();
    final store = context.read<LearningStore>();
    try {
      await vm.removeBookmark(item.templateId);
      if (mounted && !vm.disposed) store.requestRefresh();
    } catch (error) {
      if (!vm.disposed) _showError(vm.message(error));
    }
  }

  Future<void> _openResult(MyRecentResult item) async {
    final vm = context.read<MyPageViewModel>();
    await context.pushNamed(
      AppRouteNames.problemMission,
      pathParameters: {'mission': '${item.question.id}'},
    );
    if (mounted && !vm.disposed) await vm.loadRecent();
  }

  Future<void> _deleteQuestion(int id) async {
    final store = context.read<LearningStore>();
    final vm = context.read<MyPageViewModel>();
    await store.deleteMyQuestion(id);
    vm.questionDeleted(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('문제를 삭제했어요.')));
  }

  Future<void> _browse(String routeName) async {
    final vm = context.read<MyPageViewModel>();
    await context.pushNamed(routeName);
    if (mounted && !vm.disposed) await vm.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyPageViewModel>();
    final store = context.watch<LearningStore>();
    final learningCards = _learning(vm.progress.data ?? []);
    final records = vm.progress.error == null ? vm.progress.data : null;
    final complete = records?.where((item) => item.completedAt != null).length;
    return LearningTheme(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('마이페이지'),
          leading: IconButton(
            tooltip: '홈으로 돌아가기',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.goNamed(AppRouteNames.home),
          ),
          actions: [
            IconButton(
              tooltip: '기록 새로고침',
              icon: const Icon(Icons.refresh),
              onPressed: vm.refreshing ? null : _refresh,
            ),
          ],
        ),
        body: SafeArea(
          child: LearningBody(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ProgressiveCardList(
                resetScroll: false,
                resetKey: (_tab, _learningFilter),
                items: switch (_tab) {
                  _Tab.learning =>
                    vm.progress.data == null
                        ? []
                        : learningCards.skip(2).toList(),
                  _Tab.bookmarks =>
                    vm.bookmarks.data == null
                        ? []
                        : _bookmarks(vm.bookmarks.data!),
                  _Tab.results =>
                    vm.recent.data == null ? [] : _results(vm.recent.data!),
                  _Tab.generated => _generated(store),
                },
                padding: AppSpacing.pagePadding(context),
                header: [
                  _SectionContent(
                    section: vm.profile,
                    retry: vm.loadProfile,
                    builder: (profile) => _ProfileCard(
                      profile: profile,
                      onSettings: () => _browse(AppRouteNames.accountSettings),
                    ),
                  ),
                  const SizedBox(height: 20),
                  LearningCard(
                    emphasizedShadow: true,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final stacked =
                              MediaQuery.textScalerOf(context).scale(14) > 22;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 18,
                            children: [
                              for (final (label, count, icon) in [
                                (
                                  '학습 중',
                                  records == null
                                      ? null
                                      : records.length - complete!,
                                  Icons.auto_stories_outlined,
                                ),
                                ('완료', complete, Icons.task_alt),
                                (
                                  '북마크',
                                  vm.bookmarks.error == null
                                      ? vm.bookmarks.data?.length
                                      : null,
                                  Icons.bookmark_border,
                                ),
                              ])
                                SizedBox(
                                  width: stacked
                                      ? constraints.maxWidth
                                      : (constraints.maxWidth - 24) / 3,
                                  child: Column(
                                    children: [
                                      Icon(
                                        icon,
                                        color: AppColors.primary,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        count == null ? '—' : '$count',
                                        style: AppTypography.section,
                                      ),
                                      Text(label, style: AppTypography.helper),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text('나의 학습 기록', style: AppTypography.section),
                  const SizedBox(height: 8),
                  const Text(
                    '배운 내용을 돌아보고, 다음 학습을 이어가세요.',
                    style: AppTypography.helper,
                  ),
                  const SizedBox(height: 20),
                  _recordTabs(vm),
                  const SizedBox(height: 20),
                  if (vm.opening)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: LinearProgressIndicator(),
                    ),
                  if (_tab == _Tab.learning)
                    _SectionContent(
                      section: vm.progress,
                      retry: vm.loadProgress,
                      builder: (_) => const SizedBox.shrink(),
                    ),
                  if (_tab == _Tab.bookmarks)
                    _SectionContent(
                      section: vm.bookmarks,
                      retry: vm.loadBookmarks,
                      builder: (_) => const SizedBox.shrink(),
                    ),
                  if (_tab == _Tab.results) ...[
                    const Text(
                      '공개 문제와 내가 저장한 AI 문제의 최근 제출 결과를 보여드려요.',
                      style: AppTypography.helper,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '저장되지 않은 AI 연습 결과는 포함되지 않아요.',
                      style: AppTypography.meta,
                    ),
                    const SizedBox(height: 16),
                    _SectionContent(
                      section: vm.recent,
                      retry: vm.loadRecent,
                      builder: (_) => const SizedBox.shrink(),
                    ),
                  ],
                  if (_tab == _Tab.learning) ...learningCards.take(2),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _recordTabs(MyPageViewModel vm) {
    Widget chip(_Tab tab) => ChoiceChip(
      showCheckmark: false,
      labelStyle: AppTypography.link.copyWith(color: AppColors.primary),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      labelPadding: EdgeInsets.zero,
      label: Text(tab.label),
      selected: _tab == tab,
      onSelected: (_) {
        setState(() => _tab = tab);
        if (tab == _Tab.generated) {
          context.read<LearningStore>().loadMyQuestions();
        }
        if (tab == _Tab.results) vm.loadRecent();
      },
    );
    final row = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final tab in _Tab.values) ...[
          if (tab != _Tab.values.first) const SizedBox(width: 12),
          chip(tab),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: row,
        ),
      ),
    );
  }

  List<Widget> _learning(List<MyLearningRecord> items) {
    final vm = context.read<MyPageViewModel>();
    final visible = items.where(
      (item) => switch (_learningFilter) {
        _LearningFilter.all => true,
        _LearningFilter.inProgress => item.completedAt == null,
        _LearningFilter.completed => item.completedAt != null,
      },
    );
    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final filter in _LearningFilter.values)
            ChoiceChip(
              label: Text(filter.label),
              selected: _learningFilter == filter,
              showCheckmark: false,
              selectedColor: AppColors.primary,
              labelStyle: AppTypography.meta.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _learningFilter == filter
                    ? AppColors.surface
                    : AppColors.textSecondary,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(
                color: _learningFilter == filter
                    ? AppColors.primary
                    : AppColors.border,
              ),
              onSelected: (_) => setState(() => _learningFilter = filter),
            ),
        ],
      ),
      const SizedBox(height: 16),
      if (visible.isEmpty)
        _EmptyState(
          icon: Icons.auto_stories_outlined,
          text: switch (_learningFilter) {
            _LearningFilter.all => '아직 시작한 학습이 없어요.',
            _LearningFilter.inProgress => '진행 중인 학습이 없어요.',
            _LearningFilter.completed => '아직 완료한 학습이 없어요.',
          },
          action: '학습 둘러보기',
          onPressed: () => _browse(AppRouteNames.grammar),
        ),
      for (final item in visible)
        _RecordCard(
          background: item.completedAt == null
              ? AppColors.inProgressSurface
              : AppColors.completedSurface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Badge(
                    item.completedAt == null ? '학습 중' : '학습 완료',
                    item.completedAt == null
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                  Text(
                    [
                      item.categoryName,
                      item.languageName,
                    ].whereType<String>().join(' · '),
                    style: AppTypography.meta,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(item.title, style: AppTypography.card),
              const SizedBox(height: 8),
              Text(
                item.lastSectionTitle ?? '저장된 목차 위치가 없어요.',
                style: AppTypography.helper,
              ),
              const SizedBox(height: 12),
              Text(
                '최근 학습 ${_date(item.lastStudiedAt)}',
                style: AppTypography.meta,
              ),
              if (item.completedAt != null)
                Text(
                  '완료 ${_date(item.completedAt!)}',
                  style: AppTypography.meta,
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: vm.opening
                    ? null
                    : () => _openTemplate(item.templateId, item.lastSectionId),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text(item.completedAt == null ? '이어서 학습' : '다시 보기'),
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _generated(LearningStore store) {
    if (store.myQuestionsState == null ||
        store.myQuestionsState == PreviewLoadState.loading) {
      return [const Center(child: CircularProgressIndicator())];
    }
    if (store.myQuestionsState == PreviewLoadState.error) {
      return [
        Text(store.myQuestionsError ?? 'AI 생성 문제를 불러오지 못했어요.'),
        TextButton(
          onPressed: store.loadMyQuestions,
          child: const Text('다시 시도'),
        ),
      ];
    }
    if (store.myQuestions.isEmpty) {
      return [
        _EmptyState(
          icon: Icons.auto_awesome_outlined,
          text: '아직 저장한 AI 생성 문제가 없어요.',
          action: 'AI 문제 생성하기',
          onPressed: () async {
            await context.push('/problems/generate');
            if (mounted) await store.loadMyQuestions();
          },
        ),
      ];
    }
    return [
      for (final question in store.myQuestions)
        QuestionPreviewCard(
          key: ValueKey(question.id),
          item: question,
          action: store.canDeleteMyQuestion(question)
              ? QuestionDeleteButton(
                  questionTitle: question.prompt,
                  onDelete: () => _deleteQuestion(question.id),
                )
              : null,
        ),
    ];
  }

  List<Widget> _bookmarks(List<MyBookmark> items) {
    final vm = context.watch<MyPageViewModel>();
    return [
      if (items.isEmpty)
        _EmptyState(
          icon: Icons.bookmark_border,
          text: '아직 북마크한 학습이 없어요.',
          action: '학습 둘러보기',
          onPressed: () => _browse(AppRouteNames.grammar),
        ),
      for (final item in items)
        _RecordCard(
          background: AppColors.surfaceSubtle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const LearningIcon(Icons.auto_stories_outlined, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Badge('북마크', AppColors.primary),
                        _Badge(item.difficulty.label, AppColors.textSecondary),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '북마크 해제',
                    onPressed:
                        vm.removing(item.templateId) || vm.bookmarks.loading
                        ? null
                        : () => _removeBookmark(item),
                    icon: vm.removing(item.templateId)
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.bookmark, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(item.title, style: AppTypography.card),
              if (item.summary?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(item.summary!, style: AppTypography.helper),
              ],
              const SizedBox(height: 12),
              _RecordDate('저장 ${_date(item.createdAt)}'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: vm.opening
                    ? null
                    : () => _openTemplate(item.templateId),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('학습 열기'),
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _results(List<MyRecentResult> items) => [
    if (items.isEmpty)
      _EmptyState(
        icon: Icons.quiz_outlined,
        text: '조회 가능한 최근 제출 결과가 없어요.',
        action: '문제 둘러보기',
        onPressed: () => _browse(AppRouteNames.problems),
      ),
    for (final item in items)
      _ResultCard(item: item, onPressed: () => _openResult(item)),
  ];
}

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final userId = auth.user?.userId;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('로그인이 필요합니다.')));
    }
    return ChangeNotifierProvider(
      key: ValueKey(userId),
      create: (_) =>
          MyPageViewModel(api: MyPageApi(auth.api.dio), userId: userId)
            ..loadProfile(),
      child: const _AccountSettingsBody(),
    );
  }
}

class _AccountSettingsBody extends StatelessWidget {
  const _AccountSettingsBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyPageViewModel>();
    return LearningTheme(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('계정 관리'),
          leading: IconButton(
            tooltip: '마이페이지로 돌아가기',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.goNamed(AppRouteNames.myPage),
          ),
        ),
        body: SafeArea(
          child: LearningBody(
            child: RefreshIndicator(
              onRefresh: vm.loadProfile,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSpacing.pagePadding(context),
                children: [_account(context, vm)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _account(BuildContext context, MyPageViewModel vm) {
    final auth = context.watch<AuthViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionContent(
          section: vm.profile,
          retry: vm.loadProfile,
          builder: (profile) => _RecordCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('내 정보', style: AppTypography.card),
                const SizedBox(height: 16),
                Text(
                  '닉네임: ${profile.user.nickname}',
                  style: AppTypography.body,
                ),
                const SizedBox(height: 10),
                Text('이메일: ${profile.user.email}', style: AppTypography.body),
                const SizedBox(height: 10),
                Text(
                  '가입일: ${_date(profile.createdAt)}',
                  style: AppTypography.helper,
                ),
              ],
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => context.pushNamed(AppRouteNames.passwordReset),
          icon: const Icon(Icons.lock_outline),
          label: const Text('비밀번호 재설정'),
        ),
        const SizedBox(height: 8),
        const Text('이메일 인증 후 비밀번호를 재설정할 수 있어요.', style: AppTypography.meta),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: auth.isBusy ? null : auth.logout,
          icon: const Icon(Icons.logout),
          label: const Text('로그아웃'),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.onSettings});
  final MyProfile profile;
  final VoidCallback onSettings;
  @override
  Widget build(BuildContext context) => LearningCard(
    emphasizedShadow: true,
    backgroundColor: AppColors.primarySoft,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.surface,
                child: Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'MY COBIA',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              IconButton(
                tooltip: '계정 관리',
                onPressed: onSettings,
                icon: const Icon(Icons.settings_outlined),
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(profile.user.nickname, style: AppTypography.detail),
          const SizedBox(height: 6),
          Text(profile.user.email, style: AppTypography.helper),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _Badge(
                profile.user.role == 'ADMIN' ? '관리자' : '학습자',
                AppColors.primary,
              ),
              Text('${_date(profile.createdAt)} 가입', style: AppTypography.meta),
            ],
          ),
        ],
      ),
    ),
  );
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.child, this.background = AppColors.surface});
  final Widget child;
  final Color background;
  @override
  Widget build(BuildContext context) => LearningCard(
    emphasizedShadow: true,
    backgroundColor: background,
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color);
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(text, style: AppTypography.link.copyWith(color: color)),
  );
}

class _SectionContent<T> extends StatelessWidget {
  const _SectionContent({
    required this.section,
    required this.retry,
    required this.builder,
  });
  final MyPageSection<T> section;
  final Future<void> Function() retry;
  final Widget Function(T) builder;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (section.loading)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: LinearProgressIndicator(),
        ),
      if (section.error != null)
        _RecordCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(section.error!, style: AppTypography.helper),
              if (section.data != null)
                const Text('아래 내용은 이전 조회 결과입니다.', style: AppTypography.meta),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: section.loading ? null : retry,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      if (section.data != null) builder(section.data as T),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.text,
    required this.action,
    required this.onPressed,
  });
  final IconData icon;
  final String text, action;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => _RecordCard(
    child: Column(
      children: [
        Icon(icon, size: 36, color: AppColors.primary),
        const SizedBox(height: 16),
        Text(text, textAlign: TextAlign.center, style: AppTypography.helper),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: onPressed, child: Text(action)),
      ],
    ),
  );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.item, required this.onPressed});
  final MyRecentResult item;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    final result = item.submission;
    final graded = result.gradingStatus == 'COMPLETED';
    final passed = graded && result.score! >= item.question.passScore;
    final label = graded
        ? (passed ? '통과' : '미통과')
        : result.pending
        ? '채점 대기'
        : '채점 오류';
    final color = graded
        ? (passed ? AppColors.success : AppColors.error)
        : result.pending
        ? AppColors.warning
        : AppColors.error;
    return _RecordCard(
      background: graded
          ? (passed ? AppColors.completedSurface : const Color(0xFFFFEAF0))
          : result.pending
          ? AppColors.inProgressSurface
          : const Color(0xFFFFEAF0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                graded
                    ? (passed
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined)
                    : result.pending
                    ? Icons.schedule
                    : Icons.error_outline,
                color: color,
                size: 26,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _Badge(label, color),
                ),
              ),
              if (graded)
                Text(
                  '${result.score}점',
                  style: AppTypography.detail.copyWith(color: color),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(item.question.questionType.label, style: AppTypography.meta),
          const SizedBox(height: 8),
          Text(
            item.question.prompt,
            style: AppTypography.card,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          _RecordDate('제출 ${_date(result.submittedAt)}'),
          if (result.feedback?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                result.feedback!,
                style: AppTypography.helper,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(foregroundColor: color),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('문제와 최근 결과 보기'),
          ),
        ],
      ),
    );
  }
}

class _RecordDate extends StatelessWidget {
  const _RecordDate(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: 6),
      Expanded(child: Text(label, style: AppTypography.meta)),
    ],
  );
}
