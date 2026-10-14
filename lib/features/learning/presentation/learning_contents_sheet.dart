import 'package:flutter/material.dart';

import '../../../app/app_ui_tokens.dart';
import '../../../app/widgets/learning_ui.dart';
import '../data/learning_models.dart';

Future<TemplateSection?> showLearningContentsSheet(
  BuildContext context, {
  required LearningTemplate template,
  int? currentSectionId,
}) {
  FocusScope.of(context).unfocus();
  final sections = template.allSections;
  return showModalBottomSheet<TemplateSection>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: learningBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => LearningTheme(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .7,
        minChildSize: .4,
        maxChildSize: .9,
        builder: (context, controller) => SafeArea(
          top: false,
          child: LearningBody(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('학습 목차', style: AppTypography.section),
                      ),
                      IconButton(
                        tooltip: '목차 닫기',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    padding: AppSpacing.pagePadding(context, top: 8),
                    itemCount: sections.isEmpty ? 1 : sections.length,
                    itemBuilder: (context, index) {
                      if (sections.isEmpty) {
                        return const Text('아직 등록된 목차가 없어요.');
                      }
                      final section = sections[index];
                      final selected = section.id == currentSectionId;
                      return ListTile(
                        key: ValueKey('section-${section.id}'),
                        selected: selected,
                        selectedTileColor: AppColors.primarySoft,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.control),
                        ),
                        contentPadding: EdgeInsets.only(
                          left: section.parentId == null ? 12 : 28,
                          right: 12,
                        ),
                        leading: const Icon(Icons.menu_book_outlined),
                        title: Text(section.title),
                        subtitle: selected ? const Text('현재 학습 중') : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(context, section),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
