import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_card.dart';
import '../../../app/widgets/learning_overview_content.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../data/learning_models.dart';
import '../data/learning_preview_data.dart';
import 'learning_preview_store.dart';

const previewNotice = LearningNotice(
  '미리보기 · 예시 데이터이며, 학습 기록은 앱을 실행하는 동안만 유지됩니다.',
);

// The API provides an objectKey, not a public/download URL. Never load it as a URL.
class PreviewMediaList extends StatelessWidget {
  const PreviewMediaList({super.key, required this.items});
  final List<LearningMedia> items;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: LearningNotice(
            '${item.altText ?? item.originalName}\n첨부 자료는 준비 중입니다.',
            icon: Icons.image_outlined,
          ),
        ),
    ],
  );
}

String languageName(int? id) =>
    previewLanguages.where((l) => l.id == id).firstOrNull?.name ?? '언어 공통';
String categoryName(int id) =>
    previewCategories.where((c) => c.id == id).firstOrNull?.name ?? '학습';
String templateLocation(LearningTemplate item) => item.categoryId == 1
    ? '/grammar/${previewLanguages.firstWhere((l) => l.id == item.languageId).code.toLowerCase()}/chapters/${item.id}'
    : '/practical/${item.categoryId}/templates/${item.id}';
String previewDate(DateTime value) =>
    '${value.month}/${value.day} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

class PreviewContent extends StatelessWidget {
  const PreviewContent({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<LearningPreviewStore>();
    return switch (store.state) {
      PreviewLoadState.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      PreviewLoadState.error => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('학습 정보를 불러오지 못했어요.'),
              const SizedBox(height: 16),
              FilledButton(onPressed: store.load, child: const Text('다시 시도')),
            ],
          ),
        ),
      ),
      PreviewLoadState.ready => child,
    };
  }
}

class BookmarkButton extends StatefulWidget {
  const BookmarkButton({super.key, required this.templateId});
  final int templateId;
  @override
  State<BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<BookmarkButton> {
  bool _busy = false;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<LearningPreviewStore>();
    final saved = store.bookmarked(widget.templateId);
    return IconButton(
      tooltip: saved ? '북마크 해제' : '북마크 저장',
      onPressed: _busy
          ? null
          : () async {
              setState(() => _busy = true);
              try {
                await store.toggleBookmark(widget.templateId);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('북마크를 변경하지 못했어요. 다시 눌러 주세요.')),
                  );
                }
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
      icon: Icon(
        saved ? Icons.bookmark : Icons.bookmark_border,
        color: AppColors.primary,
      ),
    );
  }
}

class TemplatePreviewCard extends StatelessWidget {
  const TemplatePreviewCard({super.key, required this.item});
  final LearningTemplate item;
  @override
  Widget build(BuildContext context) {
    final progress = context.watch<LearningPreviewStore>().progress(item.id);
    return LearningCard(
      emphasizedShadow: true,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => context.push(templateLocation(item)),
            child: LearningOverviewContent(
              label:
                  '${languageName(item.languageId)} · ${categoryName(item.categoryId)}',
              title: item.title,
              description: item.summary,
              icon: item.categoryId == 1
                  ? Icons.menu_book_outlined
                  : Icons.layers_outlined,
              tags: [item.difficulty.label, progress?.label ?? '미시작'],
              footer: progress == null ? '학습 살펴보기' : '이어서 학습하기',
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: BookmarkButton(templateId: item.id),
          ),
        ],
      ),
    );
  }
}

class QuestionPreviewCard extends StatelessWidget {
  const QuestionPreviewCard({super.key, required this.item});
  final LearningQuestion item;
  @override
  Widget build(BuildContext context) {
    final latest = context.watch<LearningPreviewStore>().latest(item.id);
    return LearningCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/problems/${item.id}'),
        child: LearningOverviewContent(
          label:
              '${languageName(item.languageId)} · ${item.questionType.label}',
          title: item.prompt,
          description: '통과 기준 ${item.passScore}점',
          icon: Icons.terminal_rounded,
          tags: [item.difficulty.label],
          footer: latest == null
              ? '문제 풀기'
              : latest.pending
              ? '채점 대기 · 제출 확인'
              : '${latest.score}점 · 결과 확인',
        ),
      ),
    );
  }
}
