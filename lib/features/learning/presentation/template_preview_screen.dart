import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_ui.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../../grammar/presentation/grammar_scaffold.dart';
import '../../practical/presentation/practical_scaffold.dart';
import '../data/learning_models.dart';
import 'learning_preview_store.dart';
import 'learning_preview_widgets.dart';

class TemplatePreviewScreen extends StatefulWidget {
  const TemplatePreviewScreen({
    super.key,
    required this.templateId,
    this.sectionId,
    this.practical = false,
  });
  final int templateId;
  final int? sectionId;
  final bool practical;
  @override
  State<TemplatePreviewScreen> createState() => _TemplatePreviewScreenState();
}

class _TemplatePreviewScreenState extends State<TemplatePreviewScreen> {
  int? _selectedId;
  bool _busy = false;
  String? _error;
  final _scroll = ScrollController();

  Future<void> _save(TemplateSection section, {bool? completed}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<LearningPreviewStore>().saveProgress(
        widget.templateId,
        section.id,
        completed: completed,
      );
      if (!mounted) return;
      setState(() => _selectedId = section.id);
      if (_scroll.hasClients) _scroll.jumpTo(0);
    } catch (_) {
      if (mounted) setState(() => _error = '학습 위치를 저장하지 못했어요. 다시 눌러 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LearningPreviewStore>();
    final item = store.template(widget.templateId);
    final progress = store.progress(widget.templateId);
    final sections = item?.allSections ?? <TemplateSection>[];
    final selectedId =
        _selectedId ?? widget.sectionId ?? progress?.lastSectionId;
    final section =
        sections.where((s) => s.id == selectedId).firstOrNull ??
        sections.firstOrNull;
    final index = section == null ? -1 : sections.indexOf(section);
    final questions = store.questions
        .where((q) => q.relatedTemplateId == item?.id)
        .toList();
    final body = PreviewContent(
      child: item == null
          ? const Center(child: Text('학습을 찾을 수 없어요. 목록에서 다시 선택해 주세요.'))
          : ListView(
              controller: _scroll,
              padding: AppSpacing.pagePadding(context).copyWith(bottom: 100),
              children: [
                LearningIntro(
                  title: item.title,
                  lines: [item.description],
                  icon: Icons.menu_book_outlined,
                ),
                previewNotice,
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          LearningBadge(languageName(item.languageId)),
                          LearningBadge(item.difficulty.label),
                          LearningBadge(progress?.label ?? '미시작'),
                        ],
                      ),
                    ),
                    BookmarkButton(templateId: item.id),
                  ],
                ),
                if (progress != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '마지막 학습 ${previewDate(progress.lastStudiedAt)}${progress.completedAt == null ? '' : ' · 완료 ${previewDate(progress.completedAt!)}'}',
                      style: AppTypography.meta,
                    ),
                  ),
                const SizedBox(height: 16),
                if (_error != null) LearningNotice(_error!),
                if (sections.isEmpty)
                  const LearningNotice('아직 등록된 목차가 없어요.')
                else ...[
                  LearningSection(
                    title: '학습 목차',
                    icon: Icons.format_list_bulleted,
                    child: Column(
                      children: [
                        for (final entry in sections)
                          Padding(
                            padding: EdgeInsets.only(
                              left: entry.parentId == null ? 0 : 16,
                            ),
                            child: ListTile(
                              key: ValueKey('section-${entry.id}'),
                              selected: entry.id == section!.id,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              title: Text(entry.title),
                              leading: Icon(
                                entry.id == section.id
                                    ? Icons.play_circle_outline
                                    : Icons.article_outlined,
                              ),
                              onTap: _busy ? null : () => _save(entry),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  LearningSection(
                    title: section!.title,
                    label: '${index + 1} / ${sections.length} 목차',
                    icon: Icons.menu_book_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (section.body?.isNotEmpty == true)
                          Text(section.body!, style: AppTypography.body),
                        if (section.exampleCode?.isNotEmpty == true) ...[
                          const SizedBox(height: 16),
                          LearningCode(section.exampleCode!),
                        ],
                        if ((section.body?.isEmpty ?? true) &&
                            (section.exampleCode?.isEmpty ?? true))
                          const Text('아직 등록된 내용이 없어요.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (index > 0)
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _save(sections[index - 1]),
                          child: const Text('이전 목차'),
                        ),
                      if (index < sections.length - 1)
                        FilledButton(
                          onPressed: _busy
                              ? null
                              : () => _save(sections[index + 1]),
                          child: const Text('다음 목차'),
                        ),
                      if (progress == null)
                        OutlinedButton(
                          onPressed: _busy ? null : () => _save(section),
                          child: const Text('여기까지 학습 저장'),
                        ),
                      if (index == sections.length - 1 &&
                          progress?.completedAt == null)
                        FilledButton(
                          onPressed: _busy
                              ? null
                              : () => _save(section, completed: true),
                          child: const Text('학습 완료'),
                        ),
                      if (progress?.completedAt != null)
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _save(sections.first, completed: false),
                          child: const Text('다시 학습하기'),
                        ),
                    ],
                  ),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: LinearProgressIndicator(),
                    ),
                ],
                const SizedBox(height: 24),
                const Text('연결된 문제', style: AppTypography.section),
                const SizedBox(height: 12),
                if (questions.isEmpty)
                  const LearningNotice('이 학습에 연결된 문제가 아직 없어요.'),
                for (final question in questions)
                  QuestionPreviewCard(item: question),
              ],
            ),
    );
    return widget.practical
        ? PracticalScaffold(isDetail: true, body: body)
        : GrammarScaffold(title: item?.title ?? '문법 학습', body: body);
  }
}
