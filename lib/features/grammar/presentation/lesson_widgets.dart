import '../../../app/app_ui_tokens.dart';

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
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: const BorderSide(color: AppColors.border),
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
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
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
                color: AppColors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 14,
                height: 22 / 14,
              ),
            ),
            const SizedBox(width: 14),
            SelectableText.rich(
              TextSpan(children: _highlight(code)),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                height: 22 / 14,
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
          ? AppColors.success
          : int.tryParse(token) != null
          ? AppColors.error
          : AppColors.primary;
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
              ?.copyWith(color: AppColors.primary),
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
                                ? AppColors.primary
                                : AppColors.border,
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
