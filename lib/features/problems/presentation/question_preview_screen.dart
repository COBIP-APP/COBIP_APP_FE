import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../../learning/data/learning_models.dart';
import '../../learning/presentation/learning_detail_scaffold.dart';
import '../../learning/presentation/learning_question_card.dart';
import '../../learning/presentation/learning_preview_store.dart';
import '../../learning/presentation/learning_preview_widgets.dart';

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

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _submit(LearningQuestion item) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<LearningPreviewStore>().submit(item.id, _answer);
      if (!mounted) return;
      setState(() => _editing = false);
      if (_scroll.hasClients) _scroll.jumpTo(0);
    } catch (_) {
      if (mounted) {
        setState(() => _error = '답안을 제출하지 못했어요. 입력한 내용은 유지되니 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _retry() {
    setState(() {
      _editing = true;
      _error = null;
      _answer = '';
    });
    _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LearningPreviewStore>();
    final item = store.question(widget.questionId);
    final latest = store.latest(widget.questionId);
    final result = !_editing ? latest : null;
    final isChoice = item?.questionType == LearningQuestionType.multipleChoice;
    final correct =
        result?.gradingStatus == 'COMPLETED' &&
        result?.score != null &&
        result!.score! >= item!.passScore;
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
      fallbackLocation: '/problems',
      body: PreviewContent(
        child: item == null
            ? const Center(child: Text('문제를 찾을 수 없어요. 목록에서 다시 선택해 주세요.'))
            : ListView(
                controller: _scroll,
                padding: AppSpacing.pagePadding(context).copyWith(bottom: 100),
                children: [
                  Text(
                    '${languageName(item.languageId)} · ${item.questionType.label} · ${item.difficulty.label}',
                    style: AppTypography.meta,
                  ),
                  const SizedBox(height: 16),
                  LearningQuestionCard(
                    question: item,
                    title: '문제',
                    answer: answer,
                    result: result,
                    showSubmissionDetails: true,
                    locked: _busy || result != null,
                    onChanged: (value) => setState(() => _answer = value),
                  ),
                  const SizedBox(height: 20),
                  if (!isChoice && result == null) ...[
                    const LearningNotice(
                      '답안을 제출하면 채점 대기로 표시됩니다. 이 미리보기에서는 코드를 실행하거나 AI 채점을 하지 않습니다.',
                    ),
                    const SizedBox(height: 16),
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
                      onPressed: () => context.go('/problems'),
                      child: const Text('문제 끝내기'),
                    )
                  else
                    OutlinedButton(
                      onPressed: _retry,
                      child: Text(result.pending ? '새 답안 제출하기' : '다시 풀기'),
                    ),
                  if (related != null) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => context.push(
                        '${templateLocation(related)}${item.relatedSectionId == null ? '' : '?section=${item.relatedSectionId}'}',
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
