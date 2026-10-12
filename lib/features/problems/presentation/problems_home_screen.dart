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
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int? _languageId;
  LearningQuestionType? _type;
  bool _submittedOnly = false;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<LearningStore>();
    final items = store.questions
        .where(
          (q) =>
              store.categoryIds('CODING_PROBLEM').contains(q.categoryId) &&
              q.prompt.toLowerCase().contains(
                _search.text.trim().toLowerCase(),
              ) &&
              (_languageId == null || q.languageId == _languageId) &&
              (_type == null || q.questionType == _type) &&
              (!_submittedOnly || store.latest(q.id) != null),
        )
        .toList();
    return LearningTheme(
      child: Scaffold(
        bottomNavigationBar: const AppBottomNavigation(selectedIndex: 3),
        body: SafeArea(
          child: LearningBody(
            child: PreviewContent(
              child: ListView(
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
                        '${_languageId == null ? '전체 언어' : store.languageName(_languageId)} · ${_type?.label ?? '전체 유형'}${_submittedOnly ? ' · 제출한 문제' : ''}',
                    filtered:
                        _languageId != null || _type != null || _submittedOnly,
                    onChanged: () => setState(() {}),
                    onFilter: () async {
                      final result = await showLearningFilters(
                        context,
                        groups: [
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
                          'language': _languageId?.toString() ?? 'all',
                          'type': _type?.code ?? 'all',
                        }, markedOnly: _submittedOnly),
                        defaults: const LearningFilterValues({
                          'language': 'all',
                          'type': 'all',
                        }),
                        markedLabel: '제출한 문제만 보기',
                      );
                      if (result != null && mounted) {
                        setState(() {
                          _languageId = int.tryParse(
                            result.selections['language']!,
                          );
                          _type = LearningQuestionType.values
                              .where((t) => t.code == result.selections['type'])
                              .firstOrNull;
                          _submittedOnly = result.markedOnly;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => context.push('/problems/generate'),
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('AI 문제 생성'),
                  ),
                  const SizedBox(height: 20),
                  if (items.isEmpty)
                    LearningNotice(
                      store.questions.isEmpty
                          ? '아직 등록된 문제가 없어요.'
                          : '조건에 맞는 문제가 없어요. 다른 필터를 선택해 주세요.',
                    ),
                  for (final item in items) QuestionPreviewCard(item: item),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
