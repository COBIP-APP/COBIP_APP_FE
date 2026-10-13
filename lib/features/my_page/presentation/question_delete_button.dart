import 'package:flutter/material.dart';

import '../../../app/app_ui_tokens.dart';
import '../../learning/data/learning_api.dart';

/// Confirms deletion and prevents duplicate requests while it is in progress.
class QuestionDeleteButton extends StatefulWidget {
  const QuestionDeleteButton({
    super.key,
    required this.questionTitle,
    required this.onDelete,
  });

  final String questionTitle;
  final Future<void> Function() onDelete;

  @override
  State<QuestionDeleteButton> createState() => _QuestionDeleteButtonState();
}

class _QuestionDeleteButtonState extends State<QuestionDeleteButton> {
  bool _busy = false;
  bool _deleting = false;

  Future<void> _delete() async {
    final operation = widget.onDelete;
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('문제를 삭제할까요?'),
          content: Text(
            widget.questionTitle,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('삭제'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() => _deleting = true);
      await operation();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is LearningApiException
                ? error.message
                : '문제를 삭제하지 못했어요. 잠시 후 다시 시도해 주세요.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _deleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: '문제 삭제',
    // Consume disabled taps so the surrounding question card does not open.
    child: GestureDetector(
      onTap: () {},
      child: OutlinedButton(
        onPressed: _busy ? null : _delete,
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_deleting)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.delete_outline),
            Text(_deleting ? '처리 중' : '삭제'),
          ],
        ),
      ),
    ),
  );
}
