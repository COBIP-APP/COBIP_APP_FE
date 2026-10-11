import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_ui.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../../learning/data/learning_models.dart';
import '../../learning/presentation/learning_preview_store.dart';
import '../../learning/presentation/learning_preview_widgets.dart';
import 'grammar_scaffold.dart';

class GrammarLessonScreen extends StatefulWidget {
  const GrammarLessonScreen({
    super.key,
    required this.templateId,
    this.sectionId,
  });
  final int templateId;
  final int? sectionId;
  @override
  State<GrammarLessonScreen> createState() => _GrammarLessonScreenState();
}

class _GrammarLessonScreenState extends State<GrammarLessonScreen> {
  final _scroll = ScrollController();
  int? _selectedId;
  bool _finished = false;
  bool _busy = false;
  String? _error;

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
      setState(() {
        _selectedId = section.id;
        _finished = completed == true;
      });
      if (_scroll.hasClients) _scroll.jumpTo(0);
    } catch (_) {
      if (mounted) setState(() => _error = '학습 위치를 저장하지 못했어요. 다시 눌러 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openContents(
    List<TemplateSection> sections,
    int? selectedId,
  ) async {
    final selected = await showModalBottomSheet<TemplateSection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: learningBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => LearningTheme(
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * .72,
            child: LearningBody(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('학습 목차', style: AppTypography.section),
                        ),
                        IconButton(
                          tooltip: '목차 닫기',
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      children: [
                        if (sections.isEmpty)
                          const LearningNotice('아직 등록된 목차가 없어요.'),
                        for (final section in sections)
                          Padding(
                            padding: EdgeInsets.only(
                              left: section.parentId == null ? 0 : 16,
                            ),
                            child: ListTile(
                              key: ValueKey('section-${section.id}'),
                              selected: section.id == selectedId,
                              title: Text(section.title),
                              leading: Icon(
                                section.id == selectedId
                                    ? Icons.play_circle_outline
                                    : Icons.article_outlined,
                              ),
                              onTap: () => Navigator.pop(sheetContext, section),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (selected != null && mounted) await _save(selected);
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
        .where((q) => q.relatedTemplateId == widget.templateId)
        .toList();
    return GrammarScaffold(
      title: item?.title ?? '문법 학습',
      actions: item == null
          ? null
          : [
              BookmarkButton(templateId: item.id),
              IconButton(
                tooltip: '목차',
                onPressed: _busy
                    ? null
                    : () => _openContents(sections, section?.id),
                icon: const Icon(Icons.format_list_bulleted),
              ),
            ],
      body: PreviewContent(
        child: item == null
            ? const Center(child: Text('학습을 찾을 수 없어요. 목록에서 다시 선택해 주세요.'))
            : ListView(
                controller: _scroll,
                padding: AppSpacing.pagePadding(context).copyWith(bottom: 100),
                children: [
                  if (_error != null) ...[
                    LearningNotice(_error!),
                    const SizedBox(height: 16),
                  ],
                  if (_finished) ...[
                    LearningSection(
                      title: '학습을 마쳤어요',
                      icon: Icons.check_circle_outline,
                      child: Text(
                        questions.isEmpty
                            ? '이 학습에 연결된 문제는 아직 없어요.'
                            : '이제 ${questions.length}개의 문제로 배운 내용을 확인해 보세요.',
                        style: AppTypography.body,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (questions.isNotEmpty)
                      FilledButton(
                        onPressed: () =>
                            context.push('/grammar-practice/${item.id}'),
                        child: const Text('문제 풀기'),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _save(sections.first, completed: false),
                      child: const Text('다시 학습하기'),
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('학습 목록으로'),
                    ),
                  ] else if (section == null)
                    const LearningNotice('아직 등록된 목차가 없어요.')
                  else ...[
                    LearningSection(
                      title: section.title,
                      emphasizedShadow: true,
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
                              (section.exampleCode?.isEmpty ?? true) &&
                              section.media.isEmpty &&
                              section.children.isEmpty)
                            const Text('아직 등록된 내용이 없어요.'),
                          PreviewMediaList(items: section.media),
                          if (section.children.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text('예제 목차', style: AppTypography.card),
                            const SizedBox(height: 8),
                            for (final child in section.children)
                              ListTile(
                                key: ValueKey('example-${child.id}'),
                                contentPadding: EdgeInsets.zero,
                                title: Text(child.title),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: _busy ? null : () => _save(child),
                              ),
                          ],
                        ],
                      ),
                    ),
                    PreviewMediaList(items: item.media),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: index > 0
                                ? OutlinedButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _save(sections[index - 1]),
                                    child: const Text('이전 목차'),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: index < sections.length - 1
                                ? FilledButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _save(sections[index + 1]),
                                    child: const Text('다음 목차'),
                                  )
                                : FilledButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _save(section, completed: true),
                                    child: const Text('학습 완료'),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (progress == null)
                          OutlinedButton(
                            onPressed: _busy ? null : () => _save(section),
                            child: const Text('여기까지 학습 저장'),
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
                  ],
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
      ),
    );
  }
}
