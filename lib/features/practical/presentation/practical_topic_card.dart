import 'package:flutter/material.dart';

import '../data/practical_sample_data.dart';

class PracticalTopicCard extends StatelessWidget {
  const PracticalTopicCard({
    super.key,
    required this.topic,
    required this.onTap,
  });

  final PracticalTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final icon = switch (topic.id) {
      'cache' => Icons.layers_outlined,
      'database' => Icons.storage_rounded,
      'network' => Icons.language_rounded,
      _ => Icons.analytics_outlined,
    };
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A292638),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withValues(alpha: 0.16)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: color, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          topic.category,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.north_east_rounded,
                        color: color.withValues(alpha: 0.65),
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    topic.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF292638),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    topic.summary,
                    style: const TextStyle(
                      color: Color(0xFF706B7F),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in topic.tags)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Divider(height: 1, color: color.withValues(alpha: 0.12)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.menu_book_rounded, color: color, size: 17),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${topic.chapters.length}개 챕터',
                          style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: color,
                        ),
                      ),
                    ],
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
