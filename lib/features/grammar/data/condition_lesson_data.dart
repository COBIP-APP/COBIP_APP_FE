import 'grammar_sample_data.dart';

// 조건문 상세 화면 확인용 콘텐츠입니다. 실행·채점·진행률 저장은 하지 않습니다.
class ConditionLesson {
  const ConditionLesson({
    required this.points,
    required this.shortCode,
    required this.code,
    required this.flow,
  });

  final List<String> points;
  final String shortCode;
  final String code;
  final List<String> flow;
}

const conditionLessons = <GrammarLanguage, ConditionLesson>{
  GrammarLanguage.java: ConditionLesson(
    points: [
      'if는 조건이 참일 때 블록을 실행합니다.',
      'else if는 앞선 조건이 거짓일 때 다음 조건을 확인합니다.',
      'else는 앞선 조건이 모두 거짓일 때 실행합니다.',
    ],
    shortCode: 'if (score >= 60) {\n    System.out.println("합격");\n}',
    code: 'int score = 75;\n\nif (score >= 90) {\n    System.out.println("우수");\n} else if (score >= 60) {\n    System.out.println("합격");\n} else {\n    System.out.println("재도전");\n}',
    flow: [
      '정수 변수 score에 75를 저장합니다.',
      '75 >= 90은 거짓이므로 첫 번째 블록을 건너뜁니다.',
      '75 >= 60은 참이므로 "합격"을 출력합니다.',
      '실행할 분기를 찾았으므로 나머지 else 블록은 실행하지 않습니다.',
    ],
  ),
  GrammarLanguage.python: ConditionLesson(
    points: [
      'if는 조건이 참일 때 들여쓰기 된 코드를 실행합니다.',
      'elif는 앞선 조건이 거짓일 때 다음 조건을 확인합니다.',
      'else는 앞선 조건이 모두 거짓일 때 실행하며 들여쓰기로 실행 범위를 구분합니다.',
    ],
    shortCode: 'if score >= 60:\n    print("합격")',
    code: 'score = 75\n\nif score >= 90:\n    print("우수")\nelif score >= 60:\n    print("합격")\nelse:\n    print("재도전")',
    flow: [
      '변수 score에 75를 저장합니다.',
      '75 >= 90은 거짓이므로 if의 실행 코드를 건너뜁니다.',
      '75 >= 60은 참이므로 elif에서 "합격"을 출력합니다.',
      '실행할 분기를 찾았으므로 else의 코드는 실행하지 않습니다.',
    ],
  ),
  GrammarLanguage.javascript: ConditionLesson(
    points: [
      'if는 조건이 참일 때 블록을 실행합니다.',
      'else if는 앞선 조건이 거짓일 때 다음 조건을 확인합니다.',
      'else는 앞선 조건이 모두 거짓일 때 실행합니다.',
    ],
    shortCode: 'if (score >= 60) {\n    console.log("합격");\n}',
    code: 'const score = 75;\n\nif (score >= 90) {\n    console.log("우수");\n} else if (score >= 60) {\n    console.log("합격");\n} else {\n    console.log("재도전");\n}',
    flow: [
      'const로 score를 선언하고 75를 저장합니다.',
      '75 >= 90은 거짓이므로 첫 번째 블록을 건너뜁니다.',
      '75 >= 60은 참이므로 console.log로 "합격"을 출력합니다.',
      '실행할 분기를 찾았으므로 나머지 else 블록은 실행하지 않습니다.',
    ],
  ),
};
