import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../../learning/data/learning_models.dart';
import '../../learning/presentation/learning_detail_scaffold.dart';
import '../../learning/presentation/learning_question_card.dart';
import '../../learning/presentation/learning_store.dart';
import '../../learning/presentation/learning_preview_widgets.dart';
import '../data/ai_api.dart';
import '../data/ai_models.dart';
import 'ai_result_card.dart';

class QuestionPreviewScreen extends StatefulWidget {
  const QuestionPreviewScreen({super.key, required this.questionId});
  final int questionId;
  @override
  State<QuestionPreviewScreen> createState() => _QuestionPreviewScreenState();
}

class _QuestionPreviewScreenState extends State<QuestionPreviewScreen> {
  final _scroll = ScrollController();
  String _answer = '';
  String? _error;
  bool _busy = false;
  bool _editing = true;
  final _aiCancel = CancelToken();
  AiJavaGrade? _javaResult;
  String? _javaError;
  bool _javaBusy = false;

  bool _isJava(LearningStore store, LearningQuestion item) =>
      item.questionType == LearningQuestionType.codeWriting &&
      store.languages.any(
        (l) => l.id == item.languageId && l.code.toUpperCase() == 'JAVA',
      );

  @override
  void dispose() {
    _scroll.dispose();
    _aiCancel.cancel();
    super.dispose();
  }

  Future<void> _submit(LearningQuestion item) async {
    if (_busy || _javaBusy || _answer.trim().isEmpty) return;
    final store = context.read<LearningStore>();
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final submission = await store.submit(item.id, _answer);
      if (!mounted) return;
      setState(() => _editing = false);
      if (_scroll.hasClients) _scroll.jumpTo(0);
      if (_isJava(store, item) && submission.pending) {
        await _gradeJava(item, submission.sourceCode ?? _answer);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = '답안을 제출하지 못했어요. 입력한 내용은 유지되니 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _gradeJava(LearningQuestion item, String code) async {
    if (_javaBusy || code.trim().isEmpty) return;
    setState(() {
      _javaBusy = true;
      _javaError = null;
    });
    try {
      final value = await context.read<AiApi>().gradeJava(
        question: [
          item.prompt,
          if (item.codeSnippet?.isNotEmpty == true) item.codeSnippet!,
        ].join('\n\n'),
        code: code,
        cancelToken: _aiCancel,
      );
      if (mounted) setState(() => _javaResult = value);
    } catch (e) {
      if (mounted) {
        setState(
          () => _javaError = e is AiApiException
              ? e.message
              : 'AI 채점을 완료하지 못했어요.',
        );
      }
    } finally {
      if (mounted) setState(() => _javaBusy = false);
    }
  }

  void _retry() {
    setState(() {
      _editing = true;
      _error = null;
      _answer = '';
      _javaResult = null;
      _javaError = null;
    });
    _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LearningStore>();
    final item = store.question(widget.questionId);
    final latest = store.latest(widget.questionId);
    final result = !_editing ? latest : null;
    final isChoice = item?.questionType.hasChoices ?? false;
    final java = item != null && _isJava(store, item);
    final correct =
        _javaResult?.isCorrect == true ||
        (result?.gradingStatus == 'COMPLETED' &&
            result?.score != null &&
            result!.score! >= item!.passScore);
    final related = item?.relatedTemplateId == null
        ? null
        : store.template(item!.relatedTemplateId!);
    final answer = result == null
        ? _answer
        : result.selectedChoiceKey ??
              result.answerText ??
              result.sourceCode ??
              '';
    return LearningDetailScaffold(
      title: '문제 풀이',
      showChat: false,
      fallbackLocation: '/problems',
      body: LearningDetailContent(
        detailKey: 'q:${widget.questionId}',
        child: item == null
            ? const Center(child: Text('문제를 찾을 수 없어요. 목록에서 다시 선택해 주세요.'))
            : ListView(
                controller: _scroll,
                padding: AppSpacing.pagePadding(context).copyWith(bottom: 100),
                children: [
                  Text(
                    '${store.languageName(item.languageId)} · ${item.questionType.label} · ${item.difficulty.label}',
                    style: AppTypography.meta,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.creatorLabel(store.userId),
                    style: AppTypography.meta,
                  ),
                  const SizedBox(height: 16),
                  LearningQuestionCard(
                    question: item,
                    title: '문제',
                    answer: answer,
                    result: _javaResult == null ? result : null,
                    showSubmissionDetails: true,
                    locked: _busy || _javaBusy || result != null,
                    onChanged: (value) => setState(() => _answer = value),
                  ),
                  const SizedBox(height: 20),
                  if (!isChoice && result == null) ...[
                    LearningNotice(
                      java
                          ? '제출 후 AI가 Java 코드를 평가해요. 몇 분 정도 걸릴 수 있어요.'
                          : '답안 제출 후 서버에서 채점 상태를 확인할 수 있어요.',
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_javaBusy) const AiLoading('AI가 Java 코드를 평가하고 있어요…'),
                  if (_javaResult != null) ...[
                    AiResultCard(
                      key: ObjectKey(_javaResult),
                      isCorrect: _javaResult!.isCorrect,
                      score: _javaResult!.score,
                      feedback: _javaResult!.feedback,
                      formattedCode: _javaResult!.formattedCode,
                    ),
                    const SizedBox(height: 12),
                    const LearningNotice(
                      'AI 평가 결과는 이 화면에서만 유지돼요. 저장된 제출 기록의 채점 상태와 다를 수 있어요.',
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_javaError != null) ...[
                    LearningNotice(_javaError!),
                    TextButton(
                      onPressed: _javaBusy || _busy
                          ? null
                          : () => _gradeJava(item, answer),
                      child: const Text('AI 채점 다시 요청'),
                    ),
                  ],
                  if (_error != null) ...[
                    LearningNotice(_error!),
                    const SizedBox(height: 12),
                  ],
                  if (result == null) ...[
                    FilledButton(
                      onPressed: _answer.trim().isNotEmpty && !_busy
                          ? () => _submit(item)
                          : null,
                      child: Text(
                        _busy
                            ? '확인 중…'
                            : isChoice
                            ? '답 확인'
                            : '답안 제출',
                      ),
                    ),
                    if (latest != null)
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() => _editing = false),
                        child: const Text('최근 제출 결과 보기'),
                      ),
                  ] else if (correct)
                    FilledButton(
                      onPressed: _busy || _javaBusy
                          ? null
                          : () => context.go('/problems'),
                      child: const Text('문제 끝내기'),
                    )
                  else
                    OutlinedButton(
                      onPressed: _busy || _javaBusy ? null : _retry,
                      child: Text(
                        result.pending && _javaResult == null
                            ? '새 답안 제출하기'
                            : '다시 풀기',
                      ),
                    ),
                  if (related != null) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => context.push(
                        '${store.templateLocation(related)}${item.relatedSectionId == null ? '' : '?section=${item.relatedSectionId}'}',
                      ),
                      icon: const Icon(Icons.menu_book_outlined),
                      label: Text('관련 학습 · ${related.title}'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/problems'),
                    child: const Text('목록으로 돌아가기'),
                  ),
                ],
              ),
      ),
    );
  }
}
