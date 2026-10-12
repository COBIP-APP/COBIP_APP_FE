import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_ui.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../../../app/router/app_router.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../../learning/data/learning_models.dart';
import '../../learning/presentation/learning_preview_store.dart';
import '../../learning/presentation/learning_preview_widgets.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) => Theme(
    data: learningUiTheme,
    child: DefaultTabController(
      length: 4,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              '마이페이지',
              style: AppTypography.card.copyWith(fontFamily: 'Roboto'),
            ),
            leading: IconButton(
              tooltip: '홈으로 돌아가기',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.goNamed(AppRouteNames.home),
            ),
            actions: [
              IconButton(
                tooltip: '계정 관리',
                onPressed: () => DefaultTabController.of(context).animateTo(3),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
            bottom: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              dividerColor: AppColors.border,
              labelStyle: AppTypography.link,
              tabs: const [
                Tab(text: 'MY홈'),
                Tab(text: '내 학습'),
                Tab(text: '대시보드'),
                Tab(text: '계정 관리'),
              ],
            ),
          ),
          body: SafeArea(
            top: false,
            child: TabBarView(
              children: [
                _myHome(context),
                _learning(context),
                _dashboard(context),
                _account(context),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _page(BuildContext context, String id, List<Widget> children) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSpacing.contentWidth),
      child: ListView(
        key: PageStorageKey(id),
        padding: AppSpacing.pagePadding(context, top: 24),
        children: children,
      ),
    ),
  );

  Widget _myHome(BuildContext context) => _page(context, 'my-home', [
    _profile(context),
    const SizedBox(height: AppSpacing.section),
    _records(
      context,
      (store) => Column(
        children: [
          _summary(store),
          const SizedBox(height: AppSpacing.section),
          _bookmarks(context, store),
          const SizedBox(height: AppSpacing.section),
          _recent(context, store),
          const SizedBox(height: AppSpacing.section),
          _section(
            '내 학습',
            icon: Icons.menu_book_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '완료 ${_started(store).where((t) => store.progress(t.id)?.completedAt != null).length} / 시작한 학습 ${_started(store).length}',
                  style: AppTypography.card,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      DefaultTabController.of(context).animateTo(1),
                  child: const Text('내 학습 보기'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ]);

  Widget _profile(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;
    return _section(
      '내 프로필',
      icon: Icons.person_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ExcludeSemantics(
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primarySoft,
                  child: Icon(
                    Icons.person_outline,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.nickname ?? '로그인이 필요합니다',
                      style: AppTypography.detail,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.email ?? '계정 정보를 확인해 주세요.',
                      style: AppTypography.helper,
                    ),
                    const SizedBox(height: 8),
                    _badge(
                      user?.role == 'ADMIN' ? '관리자' : '학습자',
                      AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('사진 업로드와 프로필 편집은 준비 중이에요.', style: AppTypography.helper),
        ],
      ),
    );
  }

  Widget _records(
    BuildContext context,
    Widget Function(LearningPreviewStore) builder,
  ) {
    final store = context.watch<LearningPreviewStore>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '미리보기 기록 · 즐겨찾기와 학습·문제 기록은 이 앱 실행 중에만 유지되며 서버에 저장되지 않습니다.',
          style: AppTypography.helper,
        ),
        const SizedBox(height: 16),
        switch (store.state) {
          PreviewLoadState.loading => _section(
            '활동 불러오는 중',
            child: Semantics(
              label: '활동 정보를 불러오는 중',
              child: const Column(
                children: [_Skeleton(), SizedBox(height: 12), _Skeleton()],
              ),
            ),
          ),
          PreviewLoadState.error => _section(
            '활동을 불러오지 못했어요',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '다시 시도해 주세요. 계정 정보는 계속 확인할 수 있어요.',
                  style: AppTypography.helper,
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: store.load, child: const Text('다시 시도')),
              ],
            ),
          ),
          PreviewLoadState.ready => builder(store),
        },
      ],
    );
  }

  List<LearningTemplate> _started(LearningPreviewStore store) {
    final items = store.templates
        .where((t) => store.progress(t.id) != null)
        .toList();
    items.sort(
      (a, b) => store
          .progress(b.id)!
          .lastStudiedAt
          .compareTo(store.progress(a.id)!.lastStudiedAt),
    );
    return items;
  }

  Widget _summary(LearningPreviewStore store) => _section(
    '활동 요약',
    icon: Icons.bar_chart_outlined,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth < 260 ||
                MediaQuery.textScalerOf(context).scale(14) > 20
            ? constraints.maxWidth
            : (constraints.maxWidth - 24) / 3;
        return Wrap(
          spacing: 12,
          runSpacing: 16,
          children: [
            for (final metric in [
              (
                Icons.bookmark_border,
                '즐겨찾기',
                store.templates.where((t) => store.bookmarked(t.id)).length,
              ),
              (
                Icons.assignment_outlined,
                '제출한 문제',
                store.questions.where((q) => store.latest(q.id) != null).length,
              ),
              (
                Icons.check_circle_outline,
                '해결한 문제',
                store.questions.where((q) => store.solved(q.id)).length,
              ),
            ])
              SizedBox(
                width: width,
                child: Column(
                  children: [
                    Icon(metric.$1, color: AppColors.primary),
                    const SizedBox(height: 8),
                    Text('${metric.$3}', style: AppTypography.detail),
                    const SizedBox(height: 4),
                    Text(
                      metric.$2,
                      style: AppTypography.helper,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    ),
  );

  Widget _bookmarks(BuildContext context, LearningPreviewStore store) {
    final items = store.templates.where((t) => store.bookmarked(t.id)).toList();
    return _section(
      '즐겨찾기 학습 자료',
      icon: Icons.bookmark_border,
      child: items.isEmpty
          ? _empty(
              context,
              Icons.bookmark_border,
              '아직 즐겨찾기한 학습 자료가 없어요.',
              '학습 둘러보기',
              AppRouteNames.grammar,
            )
          : Column(
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _template(context, item, store),
                  ),
              ],
            ),
    );
  }

  Widget _template(
    BuildContext context,
    LearningTemplate item,
    LearningPreviewStore store,
  ) {
    final progress = store.progress(item.id);
    final section = item.allSections
        .where((s) => s.id == progress?.lastSectionId)
        .firstOrNull;
    final complete = progress?.completedAt != null;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: () => context.push(templateLocation(item)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${languageName(item.languageId)} · ${categoryName(item.categoryId)}',
                style: AppTypography.meta,
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: AppTypography.card,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                item.summary,
                style: AppTypography.helper,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              _badge(
                complete
                    ? '완료'
                    : progress == null
                    ? '미시작'
                    : '학습 중',
                complete ? AppColors.success : AppColors.primary,
              ),
              if (section != null) ...[
                const SizedBox(height: 12),
                Text('마지막 위치: ${section.title}', style: AppTypography.helper),
              ],
              const SizedBox(height: 12),
              Text(
                complete
                    ? '복습하기 →'
                    : progress == null
                    ? '학습하기 →'
                    : '이어서 학습 →',
                style: AppTypography.link.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recent(BuildContext context, LearningPreviewStore store) {
    final items =
        store.questions
            .map((q) => store.latest(q.id))
            .whereType<LearningSubmission>()
            .toList()
          ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return _section(
      '최근 문제 제출',
      child: items.isEmpty
          ? _empty(
              context,
              Icons.assignment_outlined,
              '아직 제출한 문제가 없어요.',
              '문제 둘러보기',
              AppRouteNames.problems,
            )
          : Column(
              children: [
                for (final entry in items.take(5)) ...[
                  _submission(context, store, entry),
                  if (entry != items.take(5).last)
                    const Divider(height: 32, color: AppColors.border),
                ],
              ],
            ),
    );
  }

  Widget _submission(
    BuildContext context,
    LearningPreviewStore store,
    LearningSubmission entry,
  ) {
    final question = store.question(entry.questionId)!;
    final pending = entry.pending || entry.score == null;
    final success = !pending && entry.score! >= question.passScore;
    final color = pending
        ? AppColors.warning
        : success
        ? AppColors.success
        : AppColors.error;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.control),
      onTap: () => context.push('/problems/${question.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.prompt,
              style: AppTypography.card,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _badge(
                  pending
                      ? '채점 대기'
                      : success
                      ? '정답 · 예시 판정'
                      : '오답 · 예시 판정',
                  color,
                ),
                Text(previewDate(entry.submittedAt), style: AppTypography.meta),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '제출 내용 보기 →',
              style: AppTypography.link.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _learning(BuildContext context) => _page(context, 'my-learning', [
    _title('내 학습', '마지막 학습 위치에서 이어서 학습하세요.'),
    _records(context, (store) {
      final items = _started(store);
      final completed = items
          .where((t) => store.progress(t.id)?.completedAt != null)
          .length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _section(
            '학습 현황',
            icon: Icons.trending_up,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '완료 $completed / 시작한 학습 ${items.length}',
                  style: AppTypography.card,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: items.isEmpty ? 0 : completed / items.length,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  color: AppColors.primary,
                  backgroundColor: AppColors.primarySoft,
                  semanticsLabel: '시작한 학습 ${items.length}개 중 $completed개 완료',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          if (items.isEmpty)
            _section(
              '학습 목록',
              icon: Icons.menu_book_outlined,
              child: _empty(
                context,
                Icons.menu_book_outlined,
                '아직 시작한 학습이 없어요.',
                '학습 시작하기',
                AppRouteNames.grammar,
              ),
            ),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _template(context, item, store),
            ),
        ],
      );
    }),
  ]);

  Widget _dashboard(BuildContext context) => _page(context, 'my-dashboard', [
    _title('대시보드', '이 앱에서 진행한 활동을 확인하세요.'),
    _records(
      context,
      (store) => Column(
        children: [
          _summary(store),
          const SizedBox(height: AppSpacing.section),
          _recent(context, store),
        ],
      ),
    ),
  ]);

  Widget _account(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return _page(context, 'my-account', [
      _title('계정 관리', '로그인한 계정 정보를 확인하세요.'),
      _section(
        '내 정보',
        icon: Icons.person_outline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '닉네임: ${auth.user?.nickname ?? "-"}',
              style: AppTypography.body,
            ),
            const SizedBox(height: 12),
            Text('이메일: ${auth.user?.email ?? "-"}', style: AppTypography.body),
            const SizedBox(height: 16),
            const Text('가입일은 아직 제공되지 않아요.', style: AppTypography.helper),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.section),
      _section(
        '프로필 및 보안',
        icon: Icons.lock_outline,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('프로필 사진 · 닉네임 수정', style: AppTypography.card),
            SizedBox(height: 8),
            Text('프로필 편집 기능은 준비 중이에요.', style: AppTypography.helper),
            Divider(height: 32, color: AppColors.border),
            Text('비밀번호 변경', style: AppTypography.card),
            SizedBox(height: 8),
            Text('로그인 화면의 비밀번호 찾기를 이용해 주세요.', style: AppTypography.helper),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.section),
      OutlinedButton(
        onPressed: auth.isBusy ? null : auth.logout,
        child: Text(
          auth.isBusy ? '처리 중…' : '로그아웃',
          style: AppTypography.link.copyWith(fontFamily: 'Roboto'),
        ),
      ),
    ]);
  }

  Widget _section(
    String title, {
    required Widget child,
    IconData icon = Icons.assignment_outlined,
  }) => LearningSection(
    title: title,
    icon: icon,
    emphasizedShadow: true,
    child: child,
  );

  Widget _title(String title, String description) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.section),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.title),
        const SizedBox(height: 8),
        Text(description, style: AppTypography.helper),
      ],
    ),
  );

  Widget _empty(
    BuildContext context,
    IconData icon,
    String message,
    String action,
    String route,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ExcludeSemantics(child: Icon(icon, size: 40, color: AppColors.primary)),
      const SizedBox(height: 16),
      Text(message, style: AppTypography.helper, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      OutlinedButton(
        onPressed: () => context.pushNamed(route),
        child: Text(action),
      ),
    ],
  );

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.surfaceSubtle,
      borderRadius: BorderRadius.circular(AppRadii.pill),
    ),
    child: Text(label, style: AppTypography.meta.copyWith(color: color)),
  );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
    ),
  );
}
