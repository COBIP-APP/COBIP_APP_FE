import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_card.dart';
import '../../../app/widgets/learning_overview_content.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../data/learning_models.dart';
import 'learning_store.dart';

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

String previewDate(DateTime value) {
  final local = value.toLocal();
  return '${local.month}/${local.day} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

class PreviewContent extends StatelessWidget {
  const PreviewContent({super.key, required this.child, this.onRefresh});
  final Widget child;
  final Future<void> Function()? onRefresh;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<LearningStore>();
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
              Text(store.error ?? '학습 정보를 불러오지 못했어요.'),
              const SizedBox(height: 16),
              FilledButton(onPressed: store.load, child: const Text('다시 시도')),
            ],
          ),
        ),
      ),
      PreviewLoadState.ready => RefreshIndicator(
        onRefresh: onRefresh ?? store.load,
        child: child,
      ),
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
    final store = context.watch<LearningStore>();
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
    final store = context.watch<LearningStore>();
    final progress = store.progress(item.id);
    final completed = progress?.completedAt != null;
    final started = progress != null;
    return LearningCard(
      emphasizedShadow: true,
      backgroundColor: completed
          ? AppColors.completedSurface
          : started
          ? AppColors.inProgressSurface
          : AppColors.surface,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push(store.templateLocation(item)),
        child: LearningOverviewContent(
          label:
              '${store.languageName(item.languageId)} · ${store.categoryName(item.categoryId)}',
          title: item.title,
          description: item.summary,
          icon: store.isGrammar(item)
              ? Icons.menu_book_outlined
              : Icons.layers_outlined,
          action: BookmarkButton(templateId: item.id),
          footerIcon: completed
              ? Icons.check_circle
              : started
              ? Icons.play_circle_outline
              : null,
          footerColor: completed
              ? AppColors.success
              : started
              ? AppColors.warning
              : null,
          footer: completed
              ? '${item.difficulty.label} · 학습 완료 · 복습하기'
              : '${item.difficulty.label} · ${progress?.label ?? '미시작'} · ${progress == null ? '학습하기' : '이어하기'}',
        ),
      ),
    );
  }
}

class QuestionPreviewCard extends StatelessWidget {
  const QuestionPreviewCard({super.key, required this.item, this.action});
  final LearningQuestion item;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<LearningStore>();
    final latest = store.latest(item.id);
    final solved = store.solved(item.id);
    return LearningCard(
      backgroundColor: solved
          ? AppColors.completedSurface
          : latest != null
          ? AppColors.inProgressSurface
          : AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/problems/${item.id}'),
        child: LearningOverviewContent(
          label:
              '${store.questionLanguageName(item)} · ${item.questionType.label}',
          title: item.prompt,
          action: action,
          icon: Icons.terminal_rounded,
          tags: [item.difficulty.label],
          footerIcon: solved
              ? Icons.check_circle
              : latest != null
              ? Icons.edit_note
              : null,
          footerColor: solved
              ? AppColors.success
              : latest != null
              ? AppColors.warning
              : null,
          footer: solved
              ? '맞힌 문제 · 다시 풀기'
              : latest == null
              ? '문제 풀기'
              : latest.pending
              ? '채점 대기 · 다시 풀기'
              : '제출한 문제 · 다시 풀기',
        ),
      ),
    );
  }
}

/// Loads full detail only on entry; list summaries never stand in for sections.
class LearningDetailContent extends StatelessWidget {
  const LearningDetailContent({
    super.key,
    required this.detailKey,
    required this.child,
  });
  final String detailKey;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<LearningStore>();
    if (store.state != PreviewLoadState.ready) {
      return PreviewContent(child: child);
    }
    if (store.detailReady(detailKey)) return child;
    final error = store.detailError(detailKey);
    if (error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) store.ensureDetail(detailKey);
      });
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => store.ensureDetail(detailKey, refresh: true),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
