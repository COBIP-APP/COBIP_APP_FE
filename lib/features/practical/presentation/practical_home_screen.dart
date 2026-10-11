import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_ui.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../../learning/data/learning_preview_data.dart';
import '../../learning/presentation/learning_preview_store.dart';
import '../../learning/presentation/learning_preview_widgets.dart';
import 'practical_scaffold.dart';

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
            previewNotice,
            const SizedBox(height: 20),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '주제 또는 키워드 검색',
                helperText: '현재 목록에서 검색해요.',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: '검색어 지우기',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(_search.clear),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('전체'),
                  selected: _categoryId == null,
                  onSelected: (_) => setState(() => _categoryId = null),
                ),
                for (final category in categories)
                  ChoiceChip(
                    label: Text(category.name),
                    selected: _categoryId == category.id,
                    onSelected: (_) =>
                        setState(() => _categoryId = category.id),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FilterChip(
              label: const Text('북마크만 보기'),
              selected: _bookmarksOnly,
              onSelected: (value) => setState(() => _bookmarksOnly = value),
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
