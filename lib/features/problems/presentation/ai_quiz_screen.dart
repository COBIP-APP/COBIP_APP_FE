import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_visuals.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../../learning/presentation/learning_detail_scaffold.dart';
import '../../learning/presentation/learning_store.dart';
import '../data/ai_api.dart';
import '../data/ai_models.dart';
import 'ai_quiz_view_model.dart';
import 'ai_result_card.dart';

class AiQuizScreen extends StatelessWidget {
  const AiQuizScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthViewModel>().user?.userId;
    return ChangeNotifierProvider(
      key: ValueKey(userId),
      create: (context) => AiQuizViewModel(
        context.read<AiApi>(),
        userId: userId?.toString(),
        learningStore: context.read<LearningStore>(),
      ),
      child: const _QuizPage(),
    );
  }
}

class _QuizPage extends StatefulWidget {
  const _QuizPage();
  @override
  State<_QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<_QuizPage> {
  final _form = GlobalKey<FormState>();
  final _category = TextEditingController(text: 'aws');
  final _scroll = ScrollController();
  final _types = <AiQuizType>{
    AiQuizType.multipleChoice,
    AiQuizType.blank,
    AiQuizType.descriptive,
  };
  String _difficulty = '중급';
  int _count = 1;

  @override
  void dispose() {
    _category.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _generate(AiQuizViewModel vm) async {
    if (vm.busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await vm.generate(
      category: _category.text,
      difficulty: _difficulty,
      types: _types.toList(),
      countPerType: _count,
    );
    if (mounted && vm.batch != null && _scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AiQuizViewModel>();
    final batch = vm.batch;
    return LearningDetailScaffold(
      title: 'AI 실무 문제 생성',
      showChat: false,
      fallbackLocation: '/problems',
      body: ListView(
        controller: _scroll,
        padding: AppSpacing.pagePadding(context),
        children: [
          if (batch == null)
            _buildForm(vm)
          else ...[
            Text(
              '${batch.generationTopic} · ${batch.difficulty} · ${batch.quizzes.length}문제',
              style: AppTypography.meta,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < batch.quizzes.length; i++)
                  ChoiceChip(
                    label: Text('${i + 1}번'),
                    selected: vm.index == i,
                    avatar: vm.resultAt(i) == null
                        ? null
                        : Icon(
                            vm.resultAt(i)!.isCorrect
                                ? Icons.check_circle_outline
                                : Icons.cancel_outlined,
                            color: vm.resultAt(i)!.isCorrect
                                ? AppColors.success
                                : AppColors.error,
                            size: 18,
                          ),
                    onSelected: vm.busy ? null : (_) => vm.select(i),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _QuizQuestion(
              key: ValueKey('${identityHashCode(batch)}-${vm.index}'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const ValueKey('ai-save-question'),
              onPressed: vm.busy || !vm.canSave ? null : vm.save,
              icon: Icon(
                vm.savedQuestion == null
                    ? Icons.bookmark_add_outlined
                    : Icons.check_circle_outline,
              ),
              label: Text(
                vm.saving
                    ? '저장 중…'
                    : vm.savedQuestion != null && vm.needsSolutionSave
                    ? '풀이 저장 다시 시도'
                    : vm.savedQuestion != null
                    ? '저장 완료'
                    : '문제 저장',
              ),
            ),
            if (vm.savedQuestion case final question?)
              Text(
                question.creatorLabel(context.read<LearningStore>().userId),
                style: AppTypography.meta,
              ),
            const SizedBox(height: 12),
            if (vm.result == null)
              FilledButton(
                onPressed: vm.busy || vm.answer.trim().isEmpty
                    ? null
                    : () {
                        FocusScope.of(context).unfocus();
                        vm.submit();
                      },
                child: Text(vm.busy ? '채점 중…' : '답안 제출'),
              )
            else ...[
              AiResultCard(
                key: ObjectKey(vm.result),
                isCorrect: vm.result!.isCorrect,
                feedback: vm.result!.feedback,
                correctAnswer: vm.result!.correctAnswer,
                explanation: batch.quizzes[vm.index].explanation,
                relatedSection: vm.result!.relatedSection,
                extra: vm.explanation == null
                    ? OutlinedButton(
                        onPressed: vm.busy ? null : vm.explain,
                        child: Text(vm.busy ? '해설 생성 중…' : '자세한 해설'),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final line in vm.explanation!.summary)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(line, style: AppTypography.body),
                            ),
                          Text(
                            vm.explanation!.detailedExplanation,
                            style: AppTypography.body,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            vm.explanation!.troubleshootingTip,
                            style: AppTypography.helper,
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              if (!vm.result!.isCorrect)
                OutlinedButton(
                  onPressed: vm.busy ? null : vm.retry,
                  child: const Text('다시 풀기'),
                ),
              if (vm.index < batch.quizzes.length - 1)
                FilledButton(
                  onPressed: vm.busy
                      ? null
                      : () {
                          vm.select(vm.index + 1);
                          _scroll.jumpTo(0);
                        },
                  child: const Text('다음 문제'),
                ),
            ],
          ],
          if (vm.busy)
            AiLoading(
              vm.saving ? '문제를 저장하고 있어요.' : 'AI가 처리하고 있어요. 몇 분 정도 걸릴 수 있어요.',
            ),
          if (vm.error != null) ...[
            const SizedBox(height: 12),
            LearningNotice(vm.error!),
          ],
          const SizedBox(height: 20),
          if (batch != null) ...[
            TextButton(
              onPressed: vm.busy ? null : vm.newBatch,
              child: const Text('새 문제 만들기'),
            ),
            TextButton(
              onPressed: vm.busy ? null : () => context.go('/problems'),
              child: const Text('목록 돌아가기'),
            ),
          ],
          const LearningNotice(
            '문제를 저장하면 기본 해설과 제출한 풀이도 함께 보관돼요. 저장한 문제를 풀면 답안과 채점 결과가 자동으로 기록돼요. 저장 전에 푼 답안은 저장할 때 다시 채점되며, 추가로 요청한 자세한 해설은 저장되지 않아요.',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildForm(AiQuizViewModel vm) => Form(
    key: _form,
    child: LearningSection(
      title: '어떤 문제를 풀어볼까요?',
      icon: Icons.auto_awesome_outlined,
      emphasizedShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const ValueKey('ai-category'),
            controller: _category,
            enabled: !vm.busy,
            decoration: const InputDecoration(
              labelText: '주제',
              hintText: '예: aws, docker, cicd',
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? '주제를 입력해 주세요.' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _difficulty,
            isExpanded: true,
            decoration: const InputDecoration(labelText: '난이도'),
            items: [
              for (final d in ['초급', '중급', '고급'])
                DropdownMenuItem(value: d, child: Text(d)),
            ],
            onChanged: vm.busy ? null : (v) => setState(() => _difficulty = v!),
          ),
          const SizedBox(height: 20),
          const Text('문제 유형 · 여러 개 선택 가능', style: AppTypography.card),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in AiQuizType.values)
                FilterChip(
                  label: Text(t.label),
                  selected: _types.contains(t),
                  onSelected: vm.busy
                      ? null
                      : (selected) => setState(() {
                          selected ? _types.add(t) : _types.remove(t);
                        }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _count,
            isExpanded: true,
            decoration: const InputDecoration(labelText: '유형별 문제 수'),
            items: [
              for (var n = 1; n <= 5; n++)
                DropdownMenuItem(value: n, child: Text('$n개')),
            ],
            onChanged: vm.busy ? null : (v) => setState(() => _count = v!),
          ),
          const SizedBox(height: 12),
          Text(
            _types.isEmpty
                ? '문제 유형을 하나 이상 선택해 주세요.'
                : '총 ${_types.length * _count}문제 · 최대 15문제',
            style: AppTypography.helper,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const ValueKey('ai-generate'),
            onPressed: vm.busy || _types.isEmpty || _types.length * _count > 15
                ? null
                : () => _generate(vm),
            icon: const Icon(Icons.auto_awesome_outlined),
            label: Text(vm.busy ? '문제 생성 중…' : '문제 생성하기'),
          ),
        ],
      ),
    ),
  );
}

class _QuizQuestion extends StatelessWidget {
  const _QuizQuestion({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AiQuizViewModel>();
    final q = vm.batch!.quizzes[vm.index];
    final locked = vm.busy || vm.result != null;
    return LearningSection(
      title: '${vm.index + 1}번 문제',
      label: q.type.label,
      icon: Icons.quiz_outlined,
      emphasizedShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(q.question, style: AppTypography.body),
          const SizedBox(height: 16),
          if (q.type.hasOptions)
            for (var i = 0; i < q.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Semantics(
                  selected: vm.answer == '${i + 1}',
                  child: OutlinedButton(
                    key: ValueKey('ai-option-${i + 1}'),
                    onPressed: locked
                        ? null
                        : () => vm.answerChanged('${i + 1}'),
                    style: OutlinedButton.styleFrom(
                      disabledForegroundColor: AppColors.textPrimary,
                      backgroundColor: vm.answer == '${i + 1}'
                          ? AppColors.primarySoft
                          : AppColors.surface,
                      side: BorderSide(
                        color: vm.answer == '${i + 1}'
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        RegExp(r'^\s*\d+[.)]').hasMatch(q.options[i])
                            ? q.options[i]
                            : '${i + 1}. ${q.options[i]}',
                      ),
                    ),
                  ),
                ),
              )
          else
            TextFormField(
              key: const ValueKey('ai-answer'),
              initialValue: vm.answer,
              enabled: !locked,
              minLines: q.type == AiQuizType.descriptive ? 4 : 2,
              maxLines: 10,
              onChanged: vm.answerChanged,
              decoration: InputDecoration(
                hintText: q.type == AiQuizType.blank
                    ? '빈칸이 여러 개면 쉼표로 구분해 주세요.'
                    : '답안을 작성해 주세요.',
              ),
            ),
        ],
      ),
    );
  }
}
