import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_ui.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../../chat/presentation/chat_panel.dart';
import '../../learning/data/learning_models.dart';
import '../../learning/presentation/learning_preview_store.dart';
import '../../learning/presentation/learning_preview_widgets.dart';
import 'submission_preview_result.dart';

class QuestionPreviewScreen extends StatefulWidget {
  const QuestionPreviewScreen({super.key, required this.questionId});
  final int questionId;
  @override
  State<QuestionPreviewScreen> createState() => _QuestionPreviewScreenState();
}

class _QuestionPreviewScreenState extends State<QuestionPreviewScreen> {
  final _answer = TextEditingController();
  final _scroll = ScrollController();
  String? _choice;
  String? _error;
  bool _busy = false;
  bool _editing = false;

  @override
  void dispose() {
    _answer.dispose();
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
      await context.read<LearningPreviewStore>().submit(
        item.id,
        item.questionType == LearningQuestionType.multipleChoice
            ? _choice!
            : _answer.text,
      );
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

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LearningPreviewStore>();
    final item = store.question(widget.questionId);
    final latest = store.latest(widget.questionId);
    final ready = item?.questionType == LearningQuestionType.multipleChoice
        ? _choice != null
        : _answer.text.trim().isNotEmpty;
    final resultVisible = latest != null && !_editing;
    final related = item?.relatedTemplateId == null
        ? null
        : store.template(item!.relatedTemplateId!);
    return LearningTheme(
      child: Scaffold(
        appBar: AppBar(
          title: Text(resultVisible ? '제출 결과' : '문제 풀이'),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'COBIA 챗봇',
          onPressed: () => showChatPanel(context),
          child: const Icon(Icons.smart_toy_outlined),
        ),
        body: SafeArea(
          child: LearningBody(
            child: PreviewContent(
              child: item == null
                  ? const Center(child: Text('문제를 찾을 수 없어요. 목록에서 다시 선택해 주세요.'))
                  : ListView(
                      controller: _scroll,
                      padding: AppSpacing.pagePadding(context)
                          .copyWith(bottom: 100),
                      children: [
                        LearningHero(
                          title: item.questionType.label,
                          eyebrow:
                              '${languageName(item.languageId)} · ${item.difficulty.label}',
                          description: '통과 기준 ${item.passScore}점',
                          art: 'login_code',
                        ),
                        const SizedBox(height: 16),
                        previewNotice,
                        const SizedBox(height: 24),
                        if (resultVisible)
                          SubmissionPreviewResult(
                            question: item,
                            submission: latest,
                          ),
                        if (!resultVisible) ...[
                          LearningSection(
                            title: '문제',
                            icon: Icons.terminal_rounded,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(item.prompt, style: AppTypography.body),
                                PreviewMediaList(items: item.media),
                                if (item.codeSnippet?.isNotEmpty == true) ...[
                                  const SizedBox(height: 16),
                                  LearningCode(item.codeSnippet!),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          LearningSection(
                            title: '답안 작성',
                            icon: Icons.edit_outlined,
                            child:
                                item.questionType ==
                                    LearningQuestionType.multipleChoice
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      for (final option in item.choiceOptions)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: Semantics(
                                            selected: _choice == option.key,
                                            child: OutlinedButton(
                                              key: ValueKey(
                                                'choice-${option.key}',
                                              ),
                                              onPressed: _busy
                                                  ? null
                                                  : () => setState(
                                                      () =>
                                                          _choice = option.key,
                                                    ),
                                              style: OutlinedButton.styleFrom(
                                                backgroundColor:
                                                    _choice == option.key
                                                    ? AppColors.primarySoft
                                                    : AppColors.surface,
                                              ),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  '${option.key}. ${option.text}',
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  )
                                : TextField(
                                    key: const ValueKey('question-answer'),
                                    controller: _answer,
                                    enabled: !_busy,
                                    onChanged: (_) => setState(() {}),
                                    minLines: 5,
                                    maxLines: 12,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    style:
                                        item.questionType ==
                                            LearningQuestionType.codeWriting
                                        ? const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 14,
                                          )
                                        : AppTypography.body,
                                    decoration: InputDecoration(
                                      hintText:
                                          item.questionType ==
                                              LearningQuestionType.codeWriting
                                          ? '// 코드를 작성하세요.'
                                          : '출력 결과와 코드의 동작 과정을 설명해 주세요.',
                                    ),
                                  ),
                          ),
                          if (item.questionType !=
                              LearningQuestionType.multipleChoice) ...[
                            const SizedBox(height: 12),
                            const LearningNotice(
                              '답안을 제출하면 채점 대기로 표시됩니다. 이 미리보기에서는 코드를 실행하거나 AI 채점을 하지 않습니다.',
                            ),
                          ],
                          const SizedBox(height: 20),
                          if (_error != null) ...[
                            LearningNotice(_error!),
                            const SizedBox(height: 12),
                          ],
                          FilledButton(
                            onPressed: ready && !_busy
                                ? () => _submit(item)
                                : null,
                            child: Text(_busy ? '제출 중…' : '답안 제출'),
                          ),
                          if (latest != null)
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => setState(() => _editing = false),
                              child: const Text('최근 제출 결과 보기'),
                            ),
                        ],
                        if (resultVisible) ...[
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: () => setState(() {
                              _editing = true;
                              _error = null;
                              _choice = null;
                              _answer.clear();
                            }),
                            child: Text(latest.pending ? '새 답안 제출하기' : '다시 풀기'),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '새로 제출하면 최근 제출 결과가 바뀝니다.',
                            style: AppTypography.meta,
                          ),
                        ],
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
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go('/problems'),
                          child: const Text('목록으로 돌아가기'),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
