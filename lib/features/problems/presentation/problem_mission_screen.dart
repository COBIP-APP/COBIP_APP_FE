import '../../chat/presentation/chat_panel.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../data/problem_sample_data.dart';
import 'problem_result_screen.dart';

class ProblemMissionScreen extends StatefulWidget {
  const ProblemMissionScreen({super.key, required this.mission});
  final ProblemMission mission;
  @override
  State<ProblemMissionScreen> createState() => _ProblemMissionScreenState();
}

class _ProblemMissionScreenState extends State<ProblemMissionScreen> {
  final _code = TextEditingController();
  final _output = TextEditingController();
  int? _choice;
  bool _submitted = false;
  bool _retry = false;
  bool _retryCode = false;
  bool _retryChoice = false;
  bool _retryOutput = false;

  void _retryWrongAnswers() {
    setState(() {
      _retryCode = !widget.mission.matchesSampleCode(_code.text);
      if (_retryCode) _code.clear();
      _retryChoice = _choice != widget.mission.correctIndex;
      _retryOutput = _output.text.trim() != widget.mission.outputAnswer;
      if (_retryChoice) _choice = null;
      if (_retryOutput) _output.clear();
      _retry = true;
      _submitted = false;
    });
  }

  @override
  void dispose() {
    _code.dispose();
    _output.dispose();
    super.dispose();
  }

  bool get _ready =>
      _code.text.trim().isNotEmpty &&
      _choice != null &&
      _output.text.trim().isNotEmpty;
  @override
  Widget build(BuildContext context) {
    final mission = widget.mission;
    if (_submitted) {
      return ProblemResultScreen(
        mission: mission,
        code: _code.text,
        choice: _choice!,
        output: _output.text.trim(),
        onRetry: _retryWrongAnswers,
        onReturn: () => context.goNamed(AppRouteNames.problems),
      );
    }
    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'COBIP 챗봇',
        shape: const CircleBorder(),
        onPressed: () => showChatPanel(context),
        child: const Icon(Icons.smart_toy_outlined),
      ),
      appBar: AppBar(
        title: Text(_retry ? '오답 다시 풀기' : '문제 풀이'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EAFF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _retry
                        ? '틀린 문제만 다시 풀어보세요. 맞힌 답은 유지됩니다.'
                        : '기초 개념을 확인하고 3개의 문제를 풀어보세요.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!_retry || _retryCode)
              _card(
                '1. ${mission.codePrompt}',
                '코드 작성형',
                TextField(
                  key: const ValueKey('problem-code'),
                  controller: _code,
                  onChanged: (_) => setState(() {}),
                  minLines: 5,
                  maxLines: 12,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: '// 코드를 작성하세요.',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            if (!_retry || _retryChoice)
              _card(
                '2. ${mission.choicePrompt}',
                '객관식',
                Column(
                  children: [
                    for (var i = 0; i < mission.options.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Semantics(
                          selected: _choice == i,
                          child: OutlinedButton(
                            onPressed: () => setState(() => _choice = i),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _choice == i
                                  ? const Color(0xFFF0EAFF)
                                  : Colors.white,
                              padding: const EdgeInsets.all(14),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _choice == i
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(mission.options[i])),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (!_retry || _retryOutput)
              _card(
                '3. 코드를 해석하고 출력값을 적어주세요.',
                '출력값 입력',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        mission.outputCode,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          height: 1.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const ValueKey('problem-output'),
                      controller: _output,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: '출력값',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            const Text(
              '더미 채점입니다. 코드는 실행하지 않고 예시 코드와 문자열을 비교하므로 다른 올바른 코드도 오답으로 표시될 수 있습니다.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: !_ready
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();
                      setState(() => _submitted = true);
                    },
              child: const Text('채점하기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, String type, Widget child) => Card(
    color: Colors.white,
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: Color(0xFFECE8F5)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            type,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, height: 1.5),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}
