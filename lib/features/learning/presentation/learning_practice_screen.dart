import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_button_shadow.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../data/learning_models.dart';
import 'learning_detail_scaffold.dart';
import 'learning_preview_widgets.dart';
import 'learning_question_card.dart';
import 'learning_store.dart';
import 'learning_flow.dart';
import 'learning_navigation.dart';
import 'learning_contents_sheet.dart';

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
  final _submitting = <int>{};
  final _errors = <int, String>{};
  bool _moving = false, _skipRequested = false;
  String? _navigationError;

  bool _graded(LearningSubmission? result) =>
      result?.gradingStatus == 'COMPLETED' && result?.score != null;

  String? _answer(LearningStore store, int id) {
    final saved = store.practiceResult(id);
    return store.practiceDraft(id) ??
        saved?.selectedChoiceKey ??
        saved?.sourceCode ??
        saved?.answerText;
  }

  Future<void> _submit(LearningQuestion question) async {
    if (_moving || _submitting.contains(question.id)) return;
    final store = context.read<LearningStore>();
    final previous = store.practiceResult(question.id);
    if (_graded(previous)) return;
    final answer = _answer(store, question.id);
    if (previous?.pending != true && (answer?.trim().isEmpty ?? true)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting.add(question.id);
      _errors.remove(question.id);
    });
    try {
      final result = previous?.pending == true
          ? await store.refreshSubmission(question.id)
          : await store.submit(question.id, answer!);
      if (mounted && result == null) {
        setState(() => _errors[question.id] = '제출 결과를 찾지 못했어요. 다시 확인해 주세요.');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errors[question.id] =
              '답안을 확인하지 못했어요. 입력한 답안은 유지됩니다. 다시 시도해 주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting.remove(question.id));
    }
  }

  Future<void> _advance(LearningFlow flow, TemplateSection section) async {
    if (_moving) return;
    setState(() {
      _moving = true;
      _navigationError = null;
    });
    try {
      final location = await flow.advance(section);
      if (mounted) context.go(location);
    } catch (_) {
      if (mounted) {
        setState(() => _navigationError = '학습 진도를 저장하지 못했어요. 다시 눌러 주세요.');
      }
    } finally {
      if (mounted) setState(() => _moving = false);
    }
  }

  Widget _question(LearningStore store, LearningQuestion question, int index) {
    final result = store.practiceResult(question.id);
    final graded = _graded(result);
    final submitting = _submitting.contains(question.id);
    final pending = result?.pending == true;
    final answer = _answer(store, question.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: LearningQuestionCard(
        key: ValueKey(question.id),
        question: question,
        title: '문제 ${index + 1}',
        answer: answer,
        result: result,
        locked: _moving || submitting || graded || pending,
        onChanged: (value) =>
            setState(() => store.rememberPracticeDraft(question.id, value)),
        submissionAction: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LearningButtonShadow(
              child: FilledButton(
                key: ValueKey('submit-${question.id}'),
                onPressed:
                    _moving ||
                        submitting ||
                        (!graded &&
                            !pending &&
                            (answer?.trim().isEmpty ?? true))
                    ? null
                    : graded
                    ? () {
                        _errors.remove(question.id);
                        store.retryPracticeQuestion(question.id);
                      }
                    : () => _submit(question),
                child: Text(
                  submitting
                      ? '확인 중…'
                      : graded
                      ? '다시 풀기'
                      : pending
                      ? '채점 결과 새로고침'
                      : result?.gradingStatus == 'FAILED'
                      ? '이 문제 다시 제출'
                      : '답 확인',
                ),
              ),
            ),
            if (_errors[question.id] != null) ...[
              const SizedBox(height: 12),
              LearningNotice(_errors[question.id]!),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LearningStore>();
    final template = store.template(widget.templateId);
    final section = template?.allSections
        .where((s) => s.id == widget.sectionId)
        .firstOrNull;
    final flow = template == null ? null : LearningFlow(store, template);
    final questions = section == null
        ? <LearningQuestion>[]
        : flow!.questionsFor(section);
    final location = template == null
        ? '/practical'
        : store.templateLocation(template);
    if (section != null &&
        questions.isEmpty &&
        !_skipRequested &&
        store.detailReady('t:${widget.templateId}')) {
      _skipRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _advance(flow!, section);
      });
    }
    return LearningDetailScaffold(
      title: section == null ? '학습 문제' : '${section.title} · 문제',
      showChat: false,
      fallbackLocation: section == null
          ? location
          : '$location?section=${section.id}',
      actions: [
        IconButton(
          tooltip: '목차',
          onPressed: template != null
              ? () async {
                  final selected = await showLearningContentsSheet(
                    context,
                    template: template,
                    currentSectionId: section?.id,
                  );
                  if (context.mounted && selected != null) {
                    context.go(flow!.lessonLocation(selected));
                  }
                }
              : null,
          icon: const Icon(Icons.format_list_bulleted),
        ),
      ],
      body: LearningDetailContent(
        detailKey: 't:${widget.templateId}',
        child: ListView(
          padding: AppSpacing.pagePadding(context),
          children: [
            if (section == null)
              const LearningNotice('학습 목차를 먼저 선택해 주세요.')
            else ...[
              if (questions.isEmpty)
                const LearningNotice('다음 학습으로 이동하고 있어요.')
              else ...[
                const Text(
                  '각 문제의 답을 확인해 보세요. 풀지 않은 문제는 나중에 다시 풀 수 있어요.',
                  style: AppTypography.body,
                ),
                const SizedBox(height: 20),
                for (var i = 0; i < questions.length; i++)
                  _question(store, questions[i], i),
              ],
              if (_navigationError != null) ...[
                LearningNotice(_navigationError!),
                const SizedBox(height: 12),
              ],
              LearningNavigation(
                keyPrefix: 'practice',
                onPrevious: () => context.go(flow!.lessonLocation(section)),
                onHome: () => context.go(flow!.homeLocation),
                onNext: () => _advance(flow!, section),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
