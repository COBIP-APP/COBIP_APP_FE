enum AiQuizType {
  multipleChoice('multiple_choice', '객관식'),
  ox('ox', 'OX'),
  shortAnswer('short_answer', '단답형'),
  blank('blank', '빈칸'),
  descriptive('descriptive', '서술형');

  const AiQuizType(this.code, this.label);
  final String code, label;
  bool get hasOptions => this == multipleChoice || this == ox;
}

Map<String, dynamic> aiObject(Object? value) {
  if (value is! Map<String, dynamic>) throw const FormatException();
  return value;
}

String aiText(Object? value) {
  if (value is! String) throw const FormatException();
  return value;
}

List<String> _strings(Object? value) {
  if (value == null) return const [];
  if (value is! List) throw const FormatException();
  return List.unmodifiable(value.map(aiText));
}

int _score(Object? value) {
  if (value is! int || value < 0 || value > 100) {
    throw const FormatException();
  }
  return value;
}

bool _bool(Object? value) {
  if (value is! bool) throw const FormatException();
  return value;
}

class AiQuiz {
  AiQuiz.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      question = aiText(json['question']),
      type = AiQuizType.values.firstWhere((t) => t.code == json['type']),
      options = _strings(json['options']),
      answer = aiText(json['answer']),
      explanation = aiText(json['explanation']),
      references = _strings(json['references']),
      gradingKeywords = _strings(json['gradingKeywords']) {
    if (id < 1 ||
        question.trim().isEmpty ||
        answer.trim().isEmpty ||
        (type.hasOptions && options.length < 2)) {
      throw const FormatException();
    }
  }

  // Generated IDs are batch-local and must never be used as BE question IDs.
  final int id;
  final String question, answer, explanation;
  final AiQuizType type;
  final List<String> options, references, gradingKeywords;

  Map<String, Object?> toJson() => {
    'id': id,
    'question': question,
    'type': type.code,
    'options': options,
    'answer': answer,
    'explanation': explanation,
    'references': references,
    'gradingKeywords': gradingKeywords,
  };
}

class AiQuizBatch {
  AiQuizBatch.fromJson(Map<String, dynamic> json, {this.requestedCategory})
    : category = aiText(json['category']),
      difficulty = aiText(json['difficulty']),
      quizzes = List.unmodifiable(
        (json['quizzes'] as List).map((q) => AiQuiz.fromJson(aiObject(q))),
      ) {
    if (quizzes.isEmpty ||
        quizzes.length != json['totalCount'] ||
        quizzes.map((q) => q.id).toSet().length != quizzes.length) {
      throw const FormatException();
    }
  }
  final String category, difficulty;
  // Keep user intent even when AI returns a broader category in its response.
  final String? requestedCategory;
  String get generationTopic => (requestedCategory ?? category).trim();
  final List<AiQuiz> quizzes;
}

class AiGrade {
  AiGrade.fromJson(Map<String, dynamic> json)
    : isCorrect = _bool(json['isCorrect']),
      score = _score(json['score']),
      feedback = aiText(json['feedback']),
      correctAnswer = aiText(json['correctAnswer']),
      explanation = aiText(json['explanation']),
      relatedSection = json['relatedSection'] == null
          ? null
          : aiText(json['relatedSection']);
  final bool isCorrect;
  final int score;
  final String feedback, correctAnswer, explanation;
  final String? relatedSection;
}

class AiJavaGrade {
  AiJavaGrade.fromJson(Map<String, dynamic> json)
    : isCorrect = _bool(json['is_correct']),
      score = _score(json['score']),
      feedback = aiText(json['feedback']),
      formattedCode = aiText(json['formatted_code']);
  final bool isCorrect;
  final int score;
  final String feedback, formattedCode;
}

class AiChatReply {
  AiChatReply.fromJson(Map<String, dynamic> json)
    : answer = aiText(json['answer']),
      source = aiText(json['source']),
      ragUsed = _bool(json['ragUsed']),
      references = List.unmodifiable(json['references'] as List),
      intent = json['intent'] == null ? null : aiText(json['intent']) {
    if (!['ollama', 'rag', 'fallback'].contains(source) ||
        answer.trim().isEmpty) {
      throw const FormatException();
    }
  }
  final String answer, source;
  final String? intent;
  final bool ragUsed;
  final List<dynamic> references;
  bool get fallback => source == 'fallback';
}

class AiExplanation {
  AiExplanation.fromJson(Map<String, dynamic> json)
    : isCorrect = _bool(json['isCorrect']),
      summary = _strings(json['summary']),
      detailedExplanation = aiText(json['detailedExplanation']),
      troubleshootingTip = aiText(json['troubleshootingTip']),
      references = List.unmodifiable(json['references'] as List);
  final bool isCorrect;
  final List<String> summary;
  final String detailedExplanation, troubleshootingTip;
  final List<dynamic> references;
}
