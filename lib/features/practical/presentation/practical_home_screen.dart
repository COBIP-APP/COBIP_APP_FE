import 'package:flutter/material.dart';

import '../data/practical_sample_data.dart';
import 'practical_scaffold.dart';

class PracticalHomeScreen extends StatefulWidget {
  const PracticalHomeScreen({super.key});
  @override
  State<PracticalHomeScreen> createState() => _PracticalHomeScreenState();
}

class _PracticalHomeScreenState extends State<PracticalHomeScreen> {
  final _search = TextEditingController();
  String? _category;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final topics = practicalTopics
        .where(
          (topic) =>
              (_category == null || topic.category == _category) &&
              '${topic.title} ${topic.summary} ${topic.tags.join(' ')}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    return PracticalScaffold(
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '실무 학습',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('개념을 넘어 실무에 한 걸음\nCOBIP와 함께 실무 기술을 학습해보세요'),
          const SizedBox(height: 24),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '주제 또는 키워드 검색',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: '검색어 지우기',
                icon: const Icon(Icons.close),
                onPressed: () => setState(_search.clear),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final category in [null, '캐시', 'DB', '네트워크', '로그'])
                ChoiceChip(
                  label: Text(category ?? '전체'),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (topics.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text('검색 결과가 없어요. 다른 키워드를 입력해보세요.'),
            ),
          for (final topic in topics)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFECE8F5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.category,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        topic.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(topic.summary),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        children: [
                          for (final tag in topic.tags)
                            ActionChip(
                              label: Text('#$tag'),
                              onPressed: () => setState(() {
                                _category = null;
                                _search.text = tag;
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${topic.chapters.length}개 챕터'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
