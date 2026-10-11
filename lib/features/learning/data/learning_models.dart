// UI models follow BE ContentDtos / ActivityDtos. No HTTP transport is used yet.
class LearningLanguage {
  const LearningLanguage(this.id, this.code, this.name);
  final int id;
  final String code;
  final String name;
}

class LearningCategory {
  const LearningCategory(this.id, this.code, this.name, {this.parentId});
  final int id;
  final String code;
  final String name;
  final int? parentId;
}

enum LearningDifficulty {
  easy('EASY', '쉬움'),
  normal('NORMAL', '보통'),
  hard('HARD', '어려움');

  const LearningDifficulty(this.code, this.label);
  final String code;
  final String label;
}

class TemplateSection {
  const TemplateSection({
    required this.id,
    required this.title,
    this.parentId,
    this.body,
    this.exampleCode,
    this.children = const [],
  });
  final int id;
  final int? parentId;
  final String title;
  final String? body;
  final String? exampleCode;
  final List<TemplateSection> children;
  Iterable<TemplateSection> get flattened sync* {
    yield this;
    for (final child in children) {
      yield* child.flattened;
    }
  }
}

class LearningTemplate {
  const LearningTemplate({
    required this.id,
    required this.title,
    required this.summary,
    required this.description,
    required this.categoryId,
    this.languageId,
    this.difficulty = LearningDifficulty.easy,
    required this.sections,
  });
  final int id;
  final String title;
  final String summary;
  final String description;
  final int categoryId;
  final int? languageId;
  final LearningDifficulty difficulty;
  final List<TemplateSection> sections;
  List<TemplateSection> get allSections =>
      sections.expand((s) => s.flattened).toList();
}

enum LearningQuestionType {
  multipleChoice('MULTIPLE_CHOICE', '객관식'),
  codeExplanation('CODE_EXPLANATION', '코드 설명'),
  codeWriting('CODE_WRITING', '코드 작성');

  const LearningQuestionType(this.code, this.label);
  final String code;
  final String label;
}

// The inner choiceOptions shape is a preview convention, pending BE agreement.
class LearningChoice {
  const LearningChoice(this.key, this.text);
  final String key;
  final String text;
}

class LearningQuestion {
  const LearningQuestion({
    required this.id,
    required this.prompt,
    required this.questionType,
    required this.categoryId,
    this.languageId,
    this.relatedTemplateId,
    this.relatedSectionId,
    this.codeSnippet,
    this.choiceOptions = const [],
    this.explanation,
    this.difficulty = LearningDifficulty.easy,
    this.passScore = 60,
  });
  final int id;
  final String prompt;
  final LearningQuestionType questionType;
  final int categoryId;
  final int? languageId;
  final int? relatedTemplateId;
  final int? relatedSectionId;
  final String? codeSnippet;
  final List<LearningChoice> choiceOptions;
  final String? explanation;
  final LearningDifficulty difficulty;
  final int passScore;
}

class LearningProgress {
  const LearningProgress({
    required this.templateId,
    required this.lastSectionId,
    required this.startedAt,
    required this.lastStudiedAt,
    this.completedAt,
  });
  final int templateId;
  final int lastSectionId;
  final DateTime startedAt;
  final DateTime lastStudiedAt;
  final DateTime? completedAt;
  String get label => completedAt == null ? '학습 중' : '완료';
}

class LearningSubmission {
  const LearningSubmission({
    required this.id,
    required this.questionId,
    required this.gradingStatus,
    required this.submittedAt,
    this.selectedChoiceKey,
    this.answerText,
    this.sourceCode,
    this.gradingMethod,
    this.score,
    this.feedback,
    this.gradedAt,
  });
  final int id;
  final int questionId;
  final String gradingStatus;
  final String? gradingMethod;
  final DateTime submittedAt;
  final DateTime? gradedAt;
  final String? selectedChoiceKey;
  final String? answerText;
  final String? sourceCode;
  final int? score;
  final String? feedback;
  bool get pending => gradingStatus == 'PENDING';
}
