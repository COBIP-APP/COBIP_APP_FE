import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_ui.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../data/learning_models.dart';
import 'learning_store.dart';
import 'learning_preview_widgets.dart';
import 'learning_detail_scaffold.dart';

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
  final _scroll = ScrollController();
  int? _selectedId;
  bool _finished = false;
  bool _busy = false;
  bool _entryRequested = false;
  String? _error;

  Future<void> _save(
    TemplateSection section, {
    bool? completed,
    bool finishReading = false,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<LearningStore>().saveProgress(
        widget.templateId,
        section.id,
        completed: completed,
      );
      if (!mounted) return;
      setState(() {
        _selectedId = section.id;
        _finished = finishReading || completed == true;
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
    final store = context.watch<LearningStore>();
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
    if (!_entryRequested &&
        store.state == PreviewLoadState.ready &&
        store.detailReady('t:${widget.templateId}') &&
        section != null) {
      _entryRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _save(section);
      });
    }
    return LearningDetailScaffold(
      title: item?.title ?? (widget.practical ? '실무 학습' : '문법 학습'),
      fallbackLocation: item == null
          ? (widget.practical ? '/practical' : '/grammar')
          : store.templateListLocation(item),
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
      body: LearningDetailContent(
        detailKey: 't:${widget.templateId}',
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
                      title: questions.isEmpty ? '학습을 마쳤어요' : '본문을 다 읽었어요',
                      emphasizedShadow: true,
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
                        onPressed: () => context.push(
                          '${widget.practical ? '/learning-practice' : '/grammar-practice'}/${item.id}',
                        ),
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
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go(store.templateListLocation(item)),
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
                                        : () => _save(
                                            section,
                                            completed: questions.isEmpty
                                                ? true
                                                : null,
                                            finishReading: true,
                                          ),
                                    child: Text(
                                      questions.isEmpty ? '학습 완료' : '본문 읽기 완료',
                                    ),
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
