import 'package:dio/dio.dart';

import 'auth_test_support.dart';
import 'learning_test_support.dart';

Map<String, Object?> generatedQuiz(int id, String type) => {
  'id': id,
  'question': '$type 문제',
  'type': type,
  'options': type == 'multiple_choice'
      ? ['1. HashMap', '2. TreeMap', '3. List', '4. Set']
      : type == 'ox'
      ? ['O', 'X']
      : null,
  'answer': type == 'multiple_choice' || type == 'ox' ? '2' : '참조 답안',
  'explanation': '생성 시 해설',
  'references': <String>[],
  'gradingKeywords': ['개념'],
};
Map<String, Object?> generatedBatch() => {
  'category': 'Infrastructure',
  'difficulty': '중급',
  'type': 'mixed',
  'quizTypes': ['multiple_choice', 'blank', 'descriptive'],
  'totalCount': 3,
  'quizzes': [
    generatedQuiz(1, 'multiple_choice'),
    generatedQuiz(2, 'blank'),
    generatedQuiz(3, 'descriptive'),
  ],
};
Map<String, Object?> quizGrade({bool correct = true}) => {
  'isCorrect': correct,
  'score': correct ? 100 : 60,
  'feedback': '채점 피드백',
  'correctAnswer': '2',
  'explanation': '채점 후 해설',
  'relatedSection': null,
};
ResponseBody aiResponse(Object data) =>
    jsonResponse({'success': true, 'message': '완료', 'data': data}, 200);

class AiTestServer extends LearningServer {
  AiTestServer() {
    handle = respondAll;
  }
  Future<ResponseBody> Function(RequestOptions)? aiHandler;
  Future<ResponseBody> respondAll(RequestOptions r) async {
    if (!r.path.startsWith('/ai/')) return respond(r);
    if (aiHandler != null) return aiHandler!(r);
    return switch (r.path) {
      '/ai/quiz/generate' => aiResponse(generatedBatch()),
      '/ai/quiz/grade' => aiResponse(quizGrade()),
      '/ai/java/grade' => aiResponse({
        'is_correct': true,
        'score': 90,
        'feedback': 'Java 피드백',
        'formatted_code': 'class Main {}',
      }),
      '/ai/chat' => aiResponse({
        'answer': '서버 챗봇 답변',
        'source': 'ollama',
        'ragUsed': false,
        'references': <Object>[],
        'intent': 'TECHNICAL',
      }),
      '/ai/quiz/explain' => aiResponse({
        'isCorrect': true,
        'summary': ['핵심 요약'],
        'detailedExplanation': '상세 해설',
        'troubleshootingTip': '실무 팁',
        'references': <Object>[],
      }),
      _ => jsonResponse({'detail': 'Not Found'}, 404),
    };
  }

  List<RequestOptions> calls(String path) =>
      requests.where((r) => r.path == path).toList();
}
