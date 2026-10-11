import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/app_bottom_navigation.dart';
import '../../../app/widgets/learning_ui.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../../learning/data/learning_models.dart';
import '../../learning/data/learning_preview_data.dart';
import '../../learning/presentation/learning_preview_store.dart';
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
    final store = context.watch<LearningPreviewStore>();
    final items = store.questions
        .where(
          (q) =>
              q.categoryId == 3 &&
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
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'COBIA',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            IconButton(
              tooltip: '프로필',
              onPressed: () => context.push('/my-page'),
              icon: const Icon(Icons.account_circle_outlined),
            ),
          ],
        ),
        bottomNavigationBar: const AppBottomNavigation(selectedIndex: 3),
        body: SafeArea(
          child: LearningBody(
            child: PreviewContent(
              child: ListView(
                padding: AppSpacing.pagePadding(context),
                children: [
                  const LearningIntro(
                    title: '문제 풀이',
                    lines: ['배운 개념을 직접 확인해보세요.', '코드 작성과 간단한 문제로 기초를 다져요.'],
                    icon: Icons.terminal_rounded,
                  ),
                  LearningListToolbar(
                    controller: _search,
                    hint: '문제 검색',
                    summary:
                        '${_languageId == null ? '전체 언어' : languageName(_languageId)} · ${_type?.label ?? '전체 유형'}${_submittedOnly ? ' · 제출한 문제' : ''}',
                    filtered:
                        _languageId != null || _type != null || _submittedOnly,
                    onChanged: () => setState(() {}),
                    onFilter: () async {
                      final result = await showLearningFilters(
                        context,
                        groups: [
                          LearningFilterGroup('language', '언어', {
                            'all': '전체 언어',
                            for (final l in previewLanguages) '${l.id}': l.name,
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
                  const SizedBox(height: 20),
                  if (items.isEmpty)
                    const LearningNotice('조건에 맞는 문제가 없어요. 다른 필터를 선택해 주세요.'),
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
