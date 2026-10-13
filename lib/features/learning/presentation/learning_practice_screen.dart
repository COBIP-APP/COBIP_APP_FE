import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../data/learning_models.dart';
import 'learning_store.dart';
import 'learning_preview_widgets.dart';
import 'learning_detail_scaffold.dart';
import 'learning_question_card.dart';

class LearningPracticeScreen extends StatefulWidget {
  const LearningPracticeScreen({
    super.key,
    required this.templateId,
    this.sectionId,
  });
  final int templateId;
  final int? sectionId;
  @override
  State<LearningPracticeScreen> createState() => _LearningPracticeScreenState();
}

class _LearningPracticeScreenState extends State<LearningPracticeScreen> {
  final _scroll = ScrollController();
  final _answers = <int, String>{};
  final _results = <int, LearningSubmission>{};
  final _errors = <int, String>{};
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool _completed(LearningSubmission? result) =>
      result?.gradingStatus == 'COMPLETED' && result?.score != null;

  Future<void> _submit(
    List<LearningQuestion> questions, {
    bool refresh = false,
  }) async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    final store = context.read<LearningStore>();
    setState(() {
      _busy = true;
      _error = null;
    });
    await Future.wait(
      questions.map((q) async {
        final previous = _results[q.id] ?? store.latest(q.id);
        if (_completed(previous)) return;
        try {
          final result = refresh || previous?.pending == true
              ? await store.refreshSubmission(q.id)
              : await store.submit(q.id, _answers[q.id]!);
          if (!mounted) return;
          setState(() {
            if (result != null) _results[q.id] = result;
            _errors.remove(q.id);
            if (result == null) _errors[q.id] = '제출 결과를 찾지 못했어요. 다시 확인해 주세요.';
          });
        } catch (_) {
          if (mounted) {
            setState(
              () => _errors[q.id] = '답안을 확인하지 못했어요. 입력한 답안은 유지됩니다. 다시 시도해 주세요.',
            );
          }
        }
      }),
    );
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _advance(
    LearningTemplate template,
    TemplateSection section,
  ) async {
    if (_busy) return;
    final store = context.read<LearningStore>();
    final sections = template.allSections;
    final index = sections.indexWhere((s) => s.id == section.id);
    final current = store.questions.where(
      (q) =>
          q.published &&
          q.relatedTemplateId == template.id &&
          q.relatedSectionId == section.id,
    );
    if (current.any((q) => !_completed(_results[q.id] ?? store.latest(q.id)))) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (index < sections.length - 1) {
        final next = sections[index + 1];
        await store.saveProgress(template.id, next.id);
        if (mounted) {
          context.go('${store.templateLocation(template)}?section=${next.id}');
        }
      } else {
        final linked = store.questions.where(
          (q) =>
              q.published &&
              q.relatedTemplateId == template.id &&
              sections.any((s) => s.id == q.relatedSectionId),
        );
        final missing = linked
            .where((q) => !_completed(_results[q.id] ?? store.latest(q.id)))
            .firstOrNull;
        if (linked.isEmpty) {
          setState(() => _error = '등록된 문제가 없어 챕터를 완료할 수 없어요. 학습 목록으로 돌아가 주세요.');
          return;
        }
        if (missing != null) {
          setState(
            () => _error = '앞선 목차에 아직 채점을 마치지 않은 문제가 있어요. 목차에서 해당 학습을 이어가 주세요.',
          );
          return;
        }
        await store.saveProgress(template.id, section.id, completed: true);
        if (mounted) context.go(store.templateListLocation(template));
      }
    } catch (_) {
      if (mounted) setState(() => _error = '학습 진도를 저장하지 못했어요. 다시 눌러 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LearningStore>();
    final template = store.template(widget.templateId);
    final section = template?.allSections
        .where((s) => s.id == widget.sectionId)
        .firstOrNull;
    final questions = store.questions
        .where(
          (q) =>
              q.published &&
              q.relatedTemplateId == widget.templateId &&
              q.relatedSectionId == section?.id &&
              section != null,
        )
        .toList();
    for (final q in questions) {
      final saved = store.latest(q.id);
      if (saved != null) {
        _answers.putIfAbsent(
          q.id,
          () =>
              saved.selectedChoiceKey ??
              saved.sourceCode ??
              saved.answerText ??
              '',
        );
      }
    }
    final done = questions.every(
      (q) => _completed(_results[q.id] ?? store.latest(q.id)),
    );
    final canSubmit = questions.every(
      (q) => _answers[q.id]?.trim().isNotEmpty == true,
    );
    final location = template == null
        ? '/grammar'
        : store.templateLocation(template);
    return LearningDetailScaffold(
      title: section == null ? '학습 확인 문제' : '${section.title} · 문제',
      showChat: false,
      fallbackLocation: location,
      body: LearningDetailContent(
        detailKey: 't:${widget.templateId}',
        child: ListView(
          controller: _scroll,
          padding: AppSpacing.pagePadding(context).copyWith(bottom: 100),
          children: [
            if (section == null)
              const LearningNotice('학습 목차를 먼저 선택해 주세요.')
            else ...[
              Text(
                '${section.title}에 연결된 문제를 풀고 채점 결과를 확인해 주세요.',
                style: AppTypography.body,
              ),
              const SizedBox(height: 20),
              if (questions.isEmpty)
                const LearningNotice('이 목차에 연결된 문제는 아직 없어요.'),
              for (var i = 0; i < questions.length; i++) ...[
                LearningQuestionCard(
                  key: ValueKey(questions[i].id),
                  question: questions[i],
                  title: '문제 ${i + 1}',
                  answer: _answers[questions[i].id],
                  result:
                      _results[questions[i].id] ??
                      store.latest(questions[i].id),
                  showSubmissionDetails: true,
                  locked:
                      _busy ||
                      _completed(
                        _results[questions[i].id] ??
                            store.latest(questions[i].id),
                      ) ||
                      (_results[questions[i].id] ??
                                  store.latest(questions[i].id))
                              ?.pending ==
                          true,
                  onChanged: (answer) =>
                      setState(() => _answers[questions[i].id] = answer),
                ),
                if (_errors[questions[i].id] != null)
                  LearningNotice(_errors[questions[i].id]!),
                if ((_results[questions[i].id] ?? store.latest(questions[i].id))
                            ?.gradingStatus ==
                        'FAILED' ||
                    _errors.containsKey(questions[i].id))
                  OutlinedButton(
                    key: ValueKey('retry-${questions[i].id}'),
                    onPressed:
                        _busy ||
                            (_answers[questions[i].id]?.trim().isEmpty ?? true)
                        ? null
                        : () => _submit([questions[i]]),
                    child: const Text('이 문제 다시 제출'),
                  ),
                if ((_results[questions[i].id] ?? store.latest(questions[i].id))
                        ?.pending ==
                    true)
                  OutlinedButton(
                    key: ValueKey('refresh-${questions[i].id}'),
                    onPressed: _busy
                        ? null
                        : () => _submit([questions[i]], refresh: true),
                    child: const Text('채점 결과 새로고침'),
                  ),
                const SizedBox(height: 24),
              ],
              if (questions.isNotEmpty && !done)
                FilledButton(
                  onPressed: !_busy && canSubmit
                      ? () => _submit(questions)
                      : null,
                  child: Text(_busy ? '확인 중…' : '답 확인'),
                ),
              if (_error != null) ...[
                LearningNotice(_error!),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: !_busy && done
                    ? () => _advance(template!, section)
                    : null,
                child: Text(_busy ? '처리 중…' : '다음'),
              ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => context.go('$location?section=${section?.id ?? ''}'),
              child: const Text('학습으로 돌아가기'),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => context.go('$location?contents=true'),
              child: const Text('목차로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}
