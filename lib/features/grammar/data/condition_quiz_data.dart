import 'condition_lesson_data.dart';
import 'grammar_sample_data.dart';

class ConditionQuestion {
  const ConditionQuestion({
    required this.question,
    required this.code,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
  final String question;
  final String code;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

// 예제와 연결된 로컬 객관식 문제입니다. 채점은 저장된 정답과 비교합니다.
List<ConditionQuestion> conditionQuestions(GrammarLanguage language) {
  final examples = conditionExamples(language);
  return [
    ConditionQuestion(
      question: '다음 코드의 출력 결과는 무엇인가요?',
      code: examples[0].code,
      options: ['재도전', '합격', '아무것도 출력하지 않음', '75'],
      correctIndex: 1,
      explanation: 'score는 75입니다. 75 >= 60이 참이므로 if 블록에서 합격을 출력합니다.',
    ),
    ConditionQuestion(
      question: '조건이 거짓일 때 어떤 결과가 출력되나요?',
      code: examples[1].code,
      options: ['이용 가능', '16', '이용 제한', '둘 다 출력'],
      correctIndex: 2,
      explanation: 'age는 16이므로 18 이상이라는 조건은 거짓입니다. else 블록에서 이용 제한을 출력합니다.',
    ),
    ConditionQuestion(
      question: '여러 조건 중 실제 실행되는 분기는 무엇인가요?',
      code: examples[2].code,
      options: [
        '60 이상인 분기만 실행',
        '90 이상인 분기만 실행',
        '마지막 else만 실행',
        '참인 조건부터 모든 분기 실행',
      ],
      correctIndex: 0,
      explanation: '75 >= 90은 거짓이고 75 >= 60은 참입니다. 처음 참이 된 분기만 실행하고 나머지는 건너뛰므로 합격을 출력합니다.',
    ),
  ];
}
