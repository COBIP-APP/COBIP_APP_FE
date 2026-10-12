import 'package:flutter/material.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_ui.dart';

class LearningFilterGroup {
  const LearningFilterGroup(this.key, this.title, this.options);
  final String key;
  final String title;
  final Map<String, String> options;
}

class LearningFilterValues {
  const LearningFilterValues(this.selections, {this.markedOnly = false});
  final Map<String, String> selections;
  final bool markedOnly;
}

Future<LearningFilterValues?> showLearningFilters(
  BuildContext context, {
  required List<LearningFilterGroup> groups,
  required LearningFilterValues current,
  required LearningFilterValues defaults,
  required String markedLabel,
}) {
  FocusScope.of(context).unfocus();
  return showModalBottomSheet<LearningFilterValues>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: learningBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _FilterSheet(
      groups: groups,
      current: current,
      defaults: defaults,
      markedLabel: markedLabel,
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.groups,
    required this.current,
    required this.defaults,
    required this.markedLabel,
  });
  final List<LearningFilterGroup> groups;
  final LearningFilterValues current, defaults;
  final String markedLabel;
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Map<String, String> _selected = Map.of(widget.current.selections);
  late bool _marked = widget.current.markedOnly;

  @override
  Widget build(BuildContext context) => LearningTheme(
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: LearningBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('필터', style: AppTypography.section),
                    ),
                    IconButton(
                      tooltip: '필터 닫기',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  children: [
                    for (final group in widget.groups) ...[
                      Text(group.title, style: AppTypography.card),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final option in group.options.entries)
                            ChoiceChip(
                              label: Text(option.value),
                              selected: _selected[group.key] == option.key,
                              onSelected: (_) => setState(
                                () => _selected[group.key] = option.key,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(widget.markedLabel),
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _marked,
                      onChanged: (value) =>
                          setState(() => _marked = value ?? false),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        _selected = Map.of(widget.defaults.selections);
                        _marked = widget.defaults.markedOnly;
                      }),
                      child: const Text('초기화'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(
                          context,
                          LearningFilterValues(_selected, markedOnly: _marked),
                        ),
                        child: const Text('적용'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// All learning lists use the same search/filter position, with no expanded chips.
class LearningListToolbar extends StatelessWidget {
  const LearningListToolbar({
    super.key,
    required this.controller,
    required this.hint,
    required this.summary,
    required this.onChanged,
    required this.onFilter,
    this.filtered = false,
  });
  final TextEditingController controller;
  final String hint, summary;
  final VoidCallback onChanged, onFilter;
  final bool filtered;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                ),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: '검색어 지우기',
                        onPressed: () {
                          controller.clear();
                          onChanged();
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: '필터',
            child: Semantics(
              selected: filtered,
              child: FilledButton.icon(
                onPressed: onFilter,
                style: FilledButton.styleFrom(
                  backgroundColor: filtered
                      ? AppColors.primary
                      : AppColors.primarySoft,
                  foregroundColor: filtered
                      ? AppColors.surface
                      : AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  elevation: 2,
                  shadowColor: AppColors.primary.withValues(alpha: .25),
                ),
                icon: Icon(
                  filtered ? Icons.filter_alt : Icons.filter_alt_outlined,
                  size: 20,
                ),
                label: const Text('필터'),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: Text(
              summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.meta,
            ),
          ),
        ],
      ),
    ],
  );
}
