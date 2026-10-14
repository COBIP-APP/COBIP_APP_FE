import '../../../app/widgets/progressive_card_list.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_ui.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../../learning/presentation/learning_store.dart';
import '../../learning/presentation/learning_preview_widgets.dart';
import 'grammar_scaffold.dart';
import '../../learning/presentation/learning_filter_sheet.dart';

class GrammarHomeScreen extends StatefulWidget {
  const GrammarHomeScreen({super.key});
  @override
  State<GrammarHomeScreen> createState() => _GrammarHomeScreenState();
}

class _GrammarHomeScreenState extends State<GrammarHomeScreen> {
  int? _languageId;
  bool _bookmarksOnly = false;
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LearningStore>();
    final language = store.languages
        .where((l) => l.id == _languageId)
        .firstOrNull;
    final query = _search.text.trim().toLowerCase();
    final items = store.templates
        .where(
          (t) =>
              store.categoryIds('GRAMMAR').contains(t.categoryId) &&
              (language == null || t.languageId == language.id) &&
              (!_bookmarksOnly || store.bookmarked(t.id)) &&
              '${t.title} ${t.summary}'.toLowerCase().contains(query),
        )
        .toList();
    return GrammarScaffold(
      title: '문법 학습',
      isOverview: true,
      body: PreviewContent(
        child: ProgressiveCardList(
          padding: AppSpacing.pagePadding(context, top: 4),
          resetKey: (_search.text, _languageId, _bookmarksOnly),
          items: [for (final item in items) TemplatePreviewCard(item: item)],
          header: [
            const SizedBox(height: 24),
            const LearningIntro(
              title: '문법 학습',
              lines: ['코드를 더 잘 이해하는 시작', 'COBIA와 함께 문법을 학습해보세요'],
              icon: Icons.menu_book_outlined,
            ),
            LearningListToolbar(
              controller: _search,
              hint: '문법 검색',
              summary:
                  '${language?.name ?? '전체 언어'}${_bookmarksOnly ? ' · 북마크' : ''}',
              filtered: language != null || _bookmarksOnly,
              onChanged: () => setState(() {}),
              onFilter: () async {
                final result = await showLearningFilters(
                  context,
                  groups: [
                    LearningFilterGroup('language', '언어', {
                      'all': '전체 언어',
                      for (final l in store.languages) '${l.id}': l.name,
                    }),
                  ],
                  current: LearningFilterValues({
                    'language': language?.id.toString() ?? 'all',
                  }, markedOnly: _bookmarksOnly),
                  defaults: const LearningFilterValues({'language': 'all'}),
                  markedLabel: '북마크만 보기',
                );
                if (result != null && mounted) {
                  setState(() {
                    _languageId = int.tryParse(
                      result.selections['language'] ?? '',
                    );
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
                    '${language?.name ?? '전체'} 문법 챕터',
                    style: AppTypography.section,
                  ),
                ),
                if (language != null || _bookmarksOnly || query.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      setState(() {
                        _languageId = null;
                        _bookmarksOnly = false;
                        _search.clear();
                      });
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
                    : query.isEmpty
                    ? '아직 등록된 학습이 없어요.'
                    : '검색 결과가 없어요. 다른 검색어를 입력해 주세요.',
              ),
          ],
        ),
      ),
    );
  }
}
