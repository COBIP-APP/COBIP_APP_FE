import 'package:flutter/material.dart';

class LessonCard extends StatelessWidget {
  const LessonCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class LessonCode extends StatelessWidget {
  const LessonCode({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final lines = code.split('\n');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          [
            for (var i = 0; i < lines.length; i++)
              '${(i + 1).toString().padLeft(2)}  ${lines[i]}',
          ].join('\n'),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            height: 1.7,
          ),
        ),
      ),
    );
  }
}

class LessonPosition extends StatelessWidget {
  const LessonPosition({super.key, required this.language});
  final String language;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$language · 제어문 · 조건문'),
        const SizedBox(height: 12),
        const Row(
          children: [
            Text('1 / 1'),
            SizedBox(width: 12),
            Expanded(child: LinearProgressIndicator(value: 1)),
          ],
        ),
        const SizedBox(height: 8),
        const Text('조건에 따라 실행하기'),
      ],
    );
  }
}
