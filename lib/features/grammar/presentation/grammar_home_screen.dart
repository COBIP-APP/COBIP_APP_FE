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
          padding: AppSpacing.pagePadding(context),
          children: [
            const LearningIntro(
              title: '문법 학습',
              lines: ['코드를 더 잘 이해하는 시작', 'COBIA와 함께 문법을 학습해보세요'],
              icon: Icons.menu_book_outlined,
            ),
            previewNotice,
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final language in previewLanguages)
                  ChoiceChip(
                    label: Text(language.name),
                    selected: _languageId == language.id,
                    onSelected: (_) =>
                        setState(() => _languageId = language.id),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: '문법 검색',
                hintText: '변수, 조건문, 반복문',
                helperText: '현재 목록에서 검색해요.',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: '검색어 지우기',
                        onPressed: () => setState(_search.clear),
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            FilterChip(
              label: const Text('북마크만 보기'),
              selected: _bookmarksOnly,
              onSelected: (value) => setState(() => _bookmarksOnly = value),
            ),
            const SizedBox(height: 24),
            Text('${language.name} 문법 챕터', style: AppTypography.section),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  context.push(
                    '/grammar/${language.code.toLowerCase()}/chapters',
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('전체 보기'),
              ),
            ),
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
