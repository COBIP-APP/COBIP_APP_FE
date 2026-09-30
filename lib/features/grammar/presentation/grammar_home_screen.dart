import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../data/grammar_sample_data.dart';
import 'grammar_scaffold.dart';

class GrammarHomeScreen extends StatefulWidget {
  const GrammarHomeScreen({super.key});

  @override
  State<GrammarHomeScreen> createState() => _GrammarHomeScreenState();
}

class _GrammarHomeScreenState extends State<GrammarHomeScreen> {
  GrammarLanguage _language = GrammarLanguage.java;
  final _searchController = TextEditingController();

  void _openChapters() {
    FocusScope.of(context).unfocus();
    context.pushNamed(
      AppRouteNames.grammarChapters,
      pathParameters: {'language': _language.id},
    );
  }

  void _openChapter(GrammarChapter chapter) {
    // 상세 화면에서 뒤로가면 해당 언어의 전체 목록으로 돌아갑니다.
    FocusScope.of(context).unfocus();
    context.goNamed(
      chapter.id == 'conditions'
          ? AppRouteNames.grammarConcept
          : AppRouteNames.grammarChapter,
      pathParameters: {
        'language': _language.id,
        if (chapter.id != 'conditions') 'chapter': chapter.id,
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final chapters = grammarSampleChapters[_language]!
        .where(
          (chapter) => '${chapter.title} ${chapter.description}'
              .toLowerCase()
              .contains(query),
        )
        .toList();
    final colors = Theme.of(context).colorScheme;

    return GrammarScaffold(
      title: '문법 학습',
      isOverview: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Text(
            '문법 학습',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('코드를 더 잘 이해하는 시작'),
          const SizedBox(height: 4),
          const Text('COBIP와 함께 문법을 학습해보세요'),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.menu_book_outlined, color: colors.primary),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '오늘 학습 $sampleDailyCompleted개',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Text('$sampleDailyCompleted / $sampleDailyGoal'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(
                    value: sampleDailyCompleted / sampleDailyGoal,
                  ),
                  const SizedBox(height: 8),
                  const Text('학습 진행률은 예시 데이터입니다.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            children: [
              for (final language in GrammarLanguage.values)
                ChoiceChip(
                  label: Text(language.label),
                  selected: _language == language,
                  onSelected: (_) => setState(() => _language = language),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: '문법 검색',
              hintText: '변수, 조건문, 반복문',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: '검색어 지우기',
                      onPressed: () => setState(_searchController.clear),
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '${_language.label} 문법 챕터',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _openChapters,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('전체 보기'),
            ),
          ),
          if (chapters.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('검색 결과가 없어요. 다른 검색어를 입력해 주세요.'),
            ),
          for (final chapter in chapters)
            Card(
              child: ListTile(
                leading: Icon(Icons.code, color: colors.primary),
                title: Text(chapter.title),
                subtitle: Text(chapter.description),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openChapter(chapter),
              ),
            ),
        ],
      ),
    );
  }
}
