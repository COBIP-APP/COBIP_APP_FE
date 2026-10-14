import '../data/learning_models.dart';
import 'learning_store.dart';

/// Both lesson and question screens advance through the server's section order.
class LearningFlow {
  LearningFlow(this.store, this.template);

  final LearningStore store;
  final LearningTemplate template;

  String get homeLocation => store.isGrammar(template)
      ? store.templateListLocation(template)
      : '/practical';

  String lessonLocation(TemplateSection section) =>
      '${store.templateLocation(template)}?section=${section.id}';

  String practiceLocation(TemplateSection section) =>
      '${store.isGrammar(template) ? '/grammar-practice' : '/learning-practice'}/${template.id}?section=${section.id}';

  List<LearningQuestion> questionsFor(TemplateSection section) => store
      .questions
      .where(
        (q) =>
            q.published &&
            q.relatedTemplateId == template.id &&
            q.relatedSectionId == section.id,
      )
      .toList();

  Future<String> previous(TemplateSection section) async {
    final sections = template.allSections;
    final index = sections.indexWhere((s) => s.id == section.id);
    if (index < 0) throw StateError('Unknown section');
    if (index == 0) return homeLocation;
    final previous = sections[index - 1];
    await store.saveProgress(template.id, previous.id);
    return questionsFor(previous).isEmpty
        ? lessonLocation(previous)
        : practiceLocation(previous);
  }

  bool get _allGraded {
    final questions = template.allSections.expand(questionsFor).toList();
    return questions.isNotEmpty &&
        questions.every((q) {
          final result = store.latest(q.id);
          return result?.gradingStatus == 'COMPLETED' && result?.score != null;
        });
  }

  Future<String> advance(TemplateSection section) async {
    final sections = template.allSections;
    final index = sections.indexWhere((s) => s.id == section.id);
    if (index < 0) throw StateError('Unknown section');
    final next = index + 1 < sections.length ? sections[index + 1] : null;
    await store.saveProgress(
      template.id,
      next?.id ?? section.id,
      completed: next == null ? _allGraded : null,
    );
    return next == null ? homeLocation : lessonLocation(next);
  }
}
