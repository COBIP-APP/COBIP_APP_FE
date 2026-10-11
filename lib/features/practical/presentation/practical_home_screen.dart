import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_ui.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../../learning/data/learning_preview_data.dart';
import '../../learning/presentation/learning_preview_store.dart';
import '../../learning/presentation/learning_preview_widgets.dart';
import 'practical_scaffold.dart';
import '../../learning/presentation/learning_filter_sheet.dart';

class PracticalHomeScreen extends StatefulWidget {
  const PracticalHomeScreen({super.key});
  @override
  State<PracticalHomeScreen> createState() => _PracticalHomeScreenState();
}

class _PracticalHomeScreenState extends State<PracticalHomeScreen> {
  final _search = TextEditingController();
  int? _categoryId;
  bool _bookmarksOnly = false;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LearningPreviewStore>();
    final categories = previewCategories.where((c) => c.parentId == 2).toList();
    final categoryIds = {2, ...categories.map((c) => c.id)};
    final query = _search.text.trim().toLowerCase();
    final items = store.templates
        .where(
          (t) =>
              categoryIds.contains(t.categoryId) &&
              (_categoryId == null || t.categoryId == _categoryId) &&
              (!_bookmarksOnly || store.bookmarked(t.id)) &&
              '${t.title} ${t.summary}'.toLowerCase().contains(query),
        )
        .toList();
    return PracticalScaffold(
      body: PreviewContent(
        child: ListView(
          padding: AppSpacing.pagePadding(context),
          children: [
            const LearningIntro(
              title: '실무 학습',
              lines: ['개념을 넘어 실무에 한 걸음', 'COBIA와 함께 실무 기술을 학습해보세요'],
              icon: Icons.layers_outlined,
            ),
            LearningListToolbar(
              controller: _search,
              hint: '주제 또는 키워드 검색',
              summary:
                  '${_categoryId == null ? '전체 분류' : categoryName(_categoryId!)}${_bookmarksOnly ? ' · 북마크' : ''}',
              filtered: _categoryId != null || _bookmarksOnly,
              onChanged: () => setState(() {}),
              onFilter: () async {
                final result = await showLearningFilters(
                  context,
                  groups: [
                    LearningFilterGroup('category', '분류', {
                      'all': '전체',
                      for (final c in categories) '${c.id}': c.name,
                    }),
                  ],
                  current: LearningFilterValues({
                    'category': _categoryId?.toString() ?? 'all',
                  }, markedOnly: _bookmarksOnly),
                  defaults: const LearningFilterValues({'category': 'all'}),
                  markedLabel: '북마크만 보기',
                );
                if (result != null && mounted) {
                  setState(() {
                    _categoryId = int.tryParse(result.selections['category']!);
                    _bookmarksOnly = result.markedOnly;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            if (items.isEmpty)
              LearningNotice(
                _bookmarksOnly
                    ? '저장한 학습이 없어요. 마음에 드는 학습을 북마크해 보세요.'
                    : '검색 결과가 없어요. 다른 키워드를 입력해보세요.',
              ),
            for (final item in items) TemplatePreviewCard(item: item),
          ],
        ),
      ),
    );
  }
}
