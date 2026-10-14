import 'package:flutter/material.dart';

import '../../../app/widgets/learning_button_shadow.dart';

/// Navigation stays available independently of answer or grading state.
class LearningNavigation extends StatelessWidget {
  const LearningNavigation({
    super.key,
    required this.keyPrefix,
    required this.onPrevious,
    required this.onHome,
    required this.onNext,
  });

  final String keyPrefix;
  final VoidCallback onPrevious;
  final VoidCallback onHome;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: LearningButtonShadow(
          child: OutlinedButton(
            key: ValueKey('$keyPrefix-previous'),
            onPressed: onPrevious,
            child: const Text('이전'),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: LearningButtonShadow(
          child: OutlinedButton(
            key: ValueKey('$keyPrefix-home'),
            onPressed: onHome,
            child: const Text('홈'),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: LearningButtonShadow(
          child: FilledButton(
            key: ValueKey('$keyPrefix-next'),
            onPressed: onNext,
            child: const Text('다음'),
          ),
        ),
      ),
    ],
  );
}
