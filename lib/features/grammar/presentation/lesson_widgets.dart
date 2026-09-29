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
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFF0EDF7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EAFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
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
        color: const Color(0xFFF5F2FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [for (var i = 0; i < lines.length; i++) '${i + 1}'].join('\n'),
              style: const TextStyle(
                color: Color(0xFF9691A5),
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.7,
              ),
            ),
            const SizedBox(width: 14),
            SelectableText.rich(
              TextSpan(children: _highlight(code)),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _highlight(String source) {
    final pattern = RegExp(
      r'"[^"\n]*"|\b(?:if|else|elif|int|const|print|console|System)\b|\b\d+\b',
    );
    final spans = <TextSpan>[];
    var offset = 0;
    for (final match in pattern.allMatches(source)) {
      if (match.start > offset) {
        spans.add(TextSpan(text: source.substring(offset, match.start)));
      }
      final token = match.group(0)!;
      final color = token.startsWith('"')
          ? const Color(0xFF25825B)
          : int.tryParse(token) != null
          ? const Color(0xFFBC4792)
          : const Color(0xFF5B3ABF);
      spans.add(
        TextSpan(
          text: token,
          style: TextStyle(color: color),
        ),
      );
      offset = match.end;
    }
    if (offset < source.length) {
      spans.add(TextSpan(text: source.substring(offset)));
    }
    return spans;
  }
}

class LessonPosition extends StatelessWidget {
  const LessonPosition({
    super.key,
    required this.language,
    this.current,
    this.total,
    this.label = '학습',
  });
  final String language;
  final int? current;
  final int? total;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$language · 제어문 · 조건문',
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
        if (current != null && total != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Text('$label $current / $total'),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    for (var i = 0; i < total!; i++)
                      Expanded(
                        child: Container(
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i < current!
                                ? Theme.of(context).colorScheme.primary
                                : const Color(0xFFECE8F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
