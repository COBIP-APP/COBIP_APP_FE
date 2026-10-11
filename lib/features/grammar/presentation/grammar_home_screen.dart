import '../../../app/widgets/app_home_header.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_ui.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../../learning/data/learning_preview_data.dart';
import '../../learning/presentation/learning_preview_store.dart';
import '../../learning/presentation/learning_preview_widgets.dart';
import 'grammar_scaffold.dart';
import '../../learning/presentation/learning_filter_sheet.dart';

class GrammarHomeScreen extends StatefulWidget {
  const GrammarHomeScreen({super.key});
  @override
  State<GrammarHomeScreen> createState() => _GrammarHomeScreenState();
}

class _GrammarHomeScreenState extends State<GrammarHomeScreen> {
  int _languageId = 1;
  bool _bookmarksOnly = false;
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LearningPreviewStore>();
    final language = previewLanguages.firstWhere((l) => l.id == _languageId);
    final query = _search.text.trim().toLowerCase();
    final items = store.templates
        .where(
          (t) =>
              t.categoryId == 1 &&
              t.languageId == _languageId &&
              (!_bookmarksOnly || store.bookmarked(t.id)) &&
              '${t.title} ${t.summary}'.toLowerCase().contains(query),
        )
        .toList();
    return GrammarScaffold(
      title: '문법 학습',
      isOverview: true,
      body: PreviewContent(
        child: ListView(
          padding: AppSpacing.pagePadding(context, top: 4),
          children: [
            const AppHomeHeader(),
            const SizedBox(height: 24),
            const LearningIntro(
              title: '문법 학습',
              lines: ['코드를 더 잘 이해하는 시작', 'COBIA와 함께 문법을 학습해보세요'],
              icon: Icons.menu_book_outlined,
            ),
            LearningListToolbar(
              controller: _search,
              hint: '문법 검색',
              summary: '${language.name}${_bookmarksOnly ? ' · 북마크' : ''}',
              filtered: _languageId != 1 || _bookmarksOnly,
              onChanged: () => setState(() {}),
              onFilter: () async {
                final result = await showLearningFilters(
                  context,
                  groups: [
                    LearningFilterGroup('language', '언어', {
                      for (final l in previewLanguages) '${l.id}': l.name,
                    }),
                  ],
                  current: LearningFilterValues({
                    'language': '$_languageId',
                  }, markedOnly: _bookmarksOnly),
                  defaults: const LearningFilterValues({'language': '1'}),
                  markedLabel: '북마크만 보기',
                );
                if (result != null && mounted) {
                  setState(() {
                    _languageId = int.parse(result.selections['language']!);
                    _bookmarksOnly = result.markedOnly;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${language.name} 문법 챕터',
                    style: AppTypography.section,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    context.push(
                      '/grammar/${language.code.toLowerCase()}/chapters',
                    );
                  },
                  child: const Text('전체 보기'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              LearningNotice(
                _bookmarksOnly
                    ? '저장한 학습이 없어요. 마음에 드는 학습을 북마크해 보세요.'
                    : '검색 결과가 없어요. 다른 검색어를 입력해 주세요.',
              ),
            for (final item in items) TemplatePreviewCard(item: item),
          ],
        ),
      ),
    );
  }
}
