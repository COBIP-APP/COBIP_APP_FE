import '../../../app/widgets/app_home_header.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/app_bottom_navigation.dart';
import '../../../app/widgets/learning_ui.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../../learning/data/learning_models.dart';
import '../../learning/presentation/learning_store.dart';
import '../../learning/presentation/learning_preview_widgets.dart';
import '../../learning/presentation/learning_filter_sheet.dart';

class ProblemsHomeScreen extends StatefulWidget {
  const ProblemsHomeScreen({super.key});
  @override
  State<ProblemsHomeScreen> createState() => _ProblemsHomeScreenState();
}

class _ProblemsHomeScreenState extends State<ProblemsHomeScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  static const _pageSize = 5;
  int _page = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = context.watch<LearningStore>();
    final userId = store.userId;
    if (userId != null &&
        store.state == PreviewLoadState.ready &&
        store.myQuestionsState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            store.userId == userId &&
            store.myQuestionsState == null) {
          store.loadMyQuestions();
        }
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  int? _languageId;
  LearningQuestionType? _type;
  bool _submittedOnly = false;
  bool _mineOnly = false;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<LearningStore>();
    final items = (_mineOnly ? store.myQuestions : store.questions)
        .where(
          (q) =>
              store.categoryIds('CODING_PROBLEM').contains(q.categoryId) &&
              (!_mineOnly || q.createdBy == store.userId) &&
              q.prompt.toLowerCase().contains(
                _search.text.trim().toLowerCase(),
              ) &&
              (_languageId == null || q.languageId == _languageId) &&
              (_type == null || q.questionType == _type) &&
              (!_submittedOnly || store.latest(q.id) != null),
        )
        .toList();
    final pageCount = (items.length / _pageSize).ceil();
    _page = _page.clamp(0, pageCount > 0 ? pageCount - 1 : 0);
    final pageItems = items.skip(_page * _pageSize).take(_pageSize);
    return LearningTheme(
      child: Scaffold(
        bottomNavigationBar: const AppBottomNavigation(selectedIndex: 3),
        body: SafeArea(
          child: LearningBody(
            child: PreviewContent(
              onRefresh: () async {
                await store.load();
                await store.loadMyQuestions();
              },
              child: ListView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSpacing.pagePadding(context, top: 4),
                children: [
                  const AppHomeHeader(),
                  const SizedBox(height: 24),
                  const LearningIntro(
                    title: '문제 풀이',
                    lines: ['배운 개념을 직접 확인해보세요.', '코드 작성과 간단한 문제로 기초를 다져요.'],
                    icon: Icons.terminal_rounded,
                  ),
                  LearningListToolbar(
                    controller: _search,
                    hint: '문제 검색',
                    summary:
                        '${_languageId == null ? '전체 언어' : store.languageName(_languageId)} · ${_type?.label ?? '전체 유형'}${_mineOnly ? ' · 내가 만든 문제' : ''}${_submittedOnly ? ' · 제출한 문제' : ''}',
                    filtered:
                        _languageId != null ||
                        _type != null ||
                        _submittedOnly ||
                        _mineOnly,
                    onChanged: () => setState(() => _page = 0),
                    onFilter: () async {
                      final result = await showLearningFilters(
                        context,
                        groups: [
                          const LearningFilterGroup('creator', '작성자', {
                            'all': '전체 문제',
                            'mine': '내가 만든 문제',
                          }),
                          LearningFilterGroup('language', '언어', {
                            'all': '전체 언어',
                            for (final l in store.languages) '${l.id}': l.name,
                          }),
                          LearningFilterGroup('type', '문제 유형', {
                            'all': '전체 유형',
                            for (final t in LearningQuestionType.values)
                              t.code: t.label,
                          }),
                        ],
                        current: LearningFilterValues({
                          'creator': _mineOnly ? 'mine' : 'all',
                          'language': _languageId?.toString() ?? 'all',
                          'type': _type?.code ?? 'all',
                        }, markedOnly: _submittedOnly),
                        defaults: const LearningFilterValues({
                          'creator': 'all',
                          'language': 'all',
                          'type': 'all',
                        }),
                        markedLabel: '제출한 문제만 보기',
                      );
                      if (result != null && mounted) {
                        setState(() {
                          _page = 0;
                          _languageId = int.tryParse(
                            result.selections['language']!,
                          );
                          _type = LearningQuestionType.values
                              .where((t) => t.code == result.selections['type'])
                              .firstOrNull;
                          _submittedOnly = result.markedOnly;
                          _mineOnly = result.selections['creator'] == 'mine';
                        });
                        if (_mineOnly) await store.loadMyQuestions();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      await context.push('/problems/generate');
                      if (mounted && _mineOnly) await store.loadMyQuestions();
                    },
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('AI 실무 문제 생성'),
                  ),
                  const SizedBox(height: 20),
                  if (store.myQuestionsState == PreviewLoadState.loading)
                    const Center(child: CircularProgressIndicator())
                  else if (store.myQuestionsState ==
                      PreviewLoadState.error) ...[
                    LearningNotice(
                      store.myQuestionsError ?? '내가 만든 문제를 불러오지 못했어요.',
                    ),
                    TextButton(
                      onPressed: store.loadMyQuestions,
                      child: const Text('다시 시도'),
                    ),
                  ],
                  if (!_mineOnly ||
                      store.myQuestionsState == PreviewLoadState.ready) ...[
                    if (items.isEmpty &&
                        store.myQuestionsState != PreviewLoadState.loading &&
                        store.myQuestionsState != PreviewLoadState.error)
                      LearningNotice(
                        _mineOnly && store.myQuestions.isEmpty
                            ? '아직 저장한 문제가 없어요. AI 문제를 만든 뒤 문제 저장을 눌러 주세요.'
                            : store.questions.isEmpty
                            ? '아직 등록된 문제가 없어요.'
                            : '조건에 맞는 문제가 없어요. 다른 필터를 선택해 주세요.',
                      ),
                    for (final item in pageItems)
                      QuestionPreviewCard(item: item),
                    if (pageCount > 1)
                      _ProblemPagination(
                        page: _page,
                        pageCount: pageCount,
                        onChanged: (page) {
                          setState(() => _page = page);
                          if (_scroll.hasClients) _scroll.jumpTo(0);
                        },
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProblemPagination extends StatelessWidget {
  const _ProblemPagination({
    required this.page,
    required this.pageCount,
    required this.onChanged,
  });
  final int page;
  final int pageCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final start = (page - 2).clamp(0, (pageCount - 5).clamp(0, pageCount));
    final end = (start + 5).clamp(0, pageCount);
    return Wrap(
      key: const ValueKey('problem-pagination'),
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton(
          tooltip: '이전 페이지',
          onPressed: page > 0 ? () => onChanged(page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        for (var i = start; i < end; i++)
          Semantics(
            selected: page == i,
            child: TextButton(
              key: ValueKey('problem-page-${i + 1}'),
              onPressed: page == i ? null : () => onChanged(i),
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                disabledForegroundColor: AppColors.primary,
                backgroundColor: page == i ? AppColors.primarySoft : null,
              ),
              child: Text('${i + 1}'),
            ),
          ),
        IconButton(
          tooltip: '다음 페이지',
          onPressed: page < pageCount - 1 ? () => onChanged(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
