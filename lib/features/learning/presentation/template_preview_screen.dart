import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_ui.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../data/learning_models.dart';
import 'learning_flow.dart';
import 'learning_navigation.dart';
import 'learning_store.dart';
import 'learning_preview_widgets.dart';
import 'learning_detail_scaffold.dart';
import 'learning_contents_sheet.dart';

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
  bool _busy = false, _entryRequested = false;
  String? _error;
  Future<void> _select(TemplateSection section) async {
    if (_busy) return;
    _entryRequested = true;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<LearningStore>().saveProgress(
        widget.templateId,
        section.id,
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

  Future<void> _practice(
    LearningTemplate template,
    TemplateSection section,
  ) async {
    if (_busy) return;
    final flow = LearningFlow(context.read<LearningStore>(), template);
    if (flow.questionsFor(section).isEmpty) {
      await _move(() => flow.advance(section));
      return;
    }
    await _select(section);
    if (!mounted || _error != null) return;
    context.go(flow.practiceLocation(section));
  }

  Future<void> _move(Future<String> Function() destination) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final location = await destination();
      if (mounted) context.go(location);
    } catch (_) {
      if (mounted) setState(() => _error = '학습 진도를 저장하지 못했어요. 다시 눌러 주세요.');
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
    final store = context.watch<LearningStore>();
    final item = store.template(widget.templateId);
    final sections = item?.allSections ?? <TemplateSection>[];
    final flow = item == null ? null : LearningFlow(store, item);
    final selectedId = _selectedId ?? widget.sectionId;
    final section =
        sections.where((s) => s.id == selectedId).firstOrNull ??
        sections.firstOrNull;
    if (!_entryRequested &&
        store.detailReady('t:${widget.templateId}') &&
        section != null) {
      _entryRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _select(section);
      });
    }
    return LearningDetailScaffold(
      chatTemplateId: widget.templateId,
      showChat: item != null,
      title: item?.title ?? (widget.practical ? '실무 학습' : '문법 학습'),
      fallbackLocation: item == null
          ? (widget.practical ? '/practical' : '/grammar')
          : flow!.homeLocation,
      actions: item == null
          ? null
          : [
              BookmarkButton(templateId: item.id),
              IconButton(
                tooltip: '목차',
                onPressed: () async {
                  final selected = await showLearningContentsSheet(
                    context,
                    template: item,
                    currentSectionId: section?.id,
                  );
                  if (mounted &&
                      selected != null &&
                      selected.id != section?.id) {
                    await _select(selected);
                  }
                },
                icon: const Icon(Icons.format_list_bulleted),
              ),
            ],
      body: LearningDetailContent(
        detailKey: 't:${widget.templateId}',
        child: item == null
            ? const Center(child: Text('학습을 찾을 수 없어요. 목록에서 다시 선택해 주세요.'))
            : ListView(
                controller: _scroll,
                padding: AppSpacing.pagePadding(context),
                children: [
                  if (_error != null) ...[
                    LearningNotice(_error!),
                    const SizedBox(height: 16),
                  ],
                  if (section == null)
                    const LearningNotice('아직 등록된 목차가 없어요.')
                  else ...[
                    LearningSection(
                      title: section.title,
                      label:
                          '${sections.indexOf(section) + 1} / ${sections.length} 목차',
                      emphasizedShadow: true,
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
                          PreviewMediaList(items: section.media),
                          if (section.children.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text('예제 목차', style: AppTypography.card),
                            for (final child in section.children)
                              ListTile(
                                key: ValueKey('example-${child.id}'),
                                title: Text(child.title),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: _busy ? null : () => _select(child),
                              ),
                          ],
                          if ((section.body?.isEmpty ?? true) &&
                              (section.exampleCode?.isEmpty ?? true) &&
                              section.media.isEmpty &&
                              section.children.isEmpty)
                            const Text('아직 등록된 내용이 없어요.'),
                        ],
                      ),
                    ),
                    PreviewMediaList(items: item.media),
                    const SizedBox(height: 24),
                    LearningNavigation(
                      keyPrefix: 'lesson',
                      onPrevious: () => _move(() => flow!.previous(section)),
                      onHome: () => context.go(flow!.homeLocation),
                      onNext: () => _practice(item, section),
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
