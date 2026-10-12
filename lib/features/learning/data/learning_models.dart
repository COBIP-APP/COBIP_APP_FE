// Screen models decoded from BE ContentDtos / ActivityDtos by LearningApi.
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

class LearningMedia {
  const LearningMedia({
    required this.id,
    required this.originalName,
    required this.objectKey,
    this.altText,
  });
  final int id;
  final String originalName;
  final String objectKey;
  final String? altText;
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
    this.media = const [],
    this.children = const [],
  });
  final int id;
  final int? parentId;
  final String title;
  final String? body;
  final String? exampleCode;
  final List<LearningMedia> media;
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
    this.media = const [],
  });
  final int id;
  final String title;
  final String summary;
  final String description;
  final int categoryId;
  final int? languageId;
  final LearningDifficulty difficulty;
  final List<TemplateSection> sections;
  final List<LearningMedia> media;
  List<TemplateSection> get allSections =>
      sections.expand((s) => s.flattened).toList();
}

enum LearningQuestionType {
  multipleChoice('MULTIPLE_CHOICE', '객관식'),
  codeExplanation('CODE_EXPLANATION', '코드 설명'),
  codeWriting('CODE_WRITING', '코드 작성'),
  ox('OX', 'OX'),
  shortAnswer('SHORT_ANSWER', '단답형'),
  fillBlank('FILL_BLANK', '빈칸'),
  descriptive('DESCRIPTIVE', '서술형');

  const LearningQuestionType(this.code, this.label);
  final String code;
  final String label;
  bool get hasChoices => this == multipleChoice || this == ox;
}

// Supported choiceOptions shape: {key, text}. Other shapes fail explicitly.
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
    this.media = const [],
    this.createdBy,
    this.creatorNickname,
    this.published = true,
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
  final List<LearningMedia> media;
  final int? createdBy;
  final String? creatorNickname;
  final bool published;

  String creatorLabel(int? currentUserId) {
    if (createdBy == null) return '작성자 정보 없음';
    final name = creatorNickname?.trim();
    return '작성자: ${name == null || name.isEmpty ? '사용자 #$createdBy' : name}'
        '${currentUserId != null && createdBy == currentUserId ? ' (나)' : ''}';
  }
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
  final int? lastSectionId;
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
  final num? score;
  final String? feedback;
  bool get pending => gradingStatus == 'PENDING';
}
