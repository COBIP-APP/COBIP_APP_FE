import 'grammar_sample_data.dart';

// 조건문 화면용 임시 콘텐츠입니다. 서버 호출과 코드 실행은 하지 않습니다.
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

class ConditionExample {
  const ConditionExample({
    required this.title,
    required this.description,
    required this.code,
    required this.flow,
    required this.output,
  });
  final String title;
  final String description;
  final String code;
  final List<String> flow;
  final String output;
}

List<ConditionExample> conditionExamples(GrammarLanguage language) {
  final lesson = conditionLessons[language]!;
  final isPython = language == GrammarLanguage.python;
  final output = language == GrammarLanguage.java
      ? 'System.out.println'
      : 'console.log';
  final declaration = language == GrammarLanguage.java ? 'int' : 'const';
  return [
    ConditionExample(
      title: 'if · 조건이 참일 때',
      description: '점수가 60 이상이면 합격을 출력합니다.',
      code: isPython
          ? 'score = 75\nif score >= 60:\n    print("합격")'
          : '$declaration score = 75;\nif (score >= 60) {\n    $output("합격");\n}',
      flow: ['score에 75를 저장합니다.', '75 >= 60은 참입니다.', '조건이 참이므로 "합격"을 출력합니다.'],
      output: '합격',
    ),
    ConditionExample(
      title: 'if / else · 두 갈래 선택',
      description: '나이가 18 이상인지 확인하고 서로 다른 결과를 출력합니다.',
      code: isPython
          ? 'age = 16\nif age >= 18:\n    print("이용 가능")\nelse:\n    print("이용 제한")'
          : '$declaration age = 16;\nif (age >= 18) {\n    $output("이용 가능");\n} else {\n    $output("이용 제한");\n}',
      flow: [
        'age에 16을 저장합니다.',
        '16 >= 18은 거짓이므로 if 블록을 건너뜁니다.',
        'else 블록에서 "이용 제한"을 출력합니다.',
      ],
      output: '이용 제한',
    ),
    ConditionExample(
      title: isPython
          ? 'if / elif / else · 여러 조건'
          : 'if / else if / else · 여러 조건',
      description: '조건을 위에서부터 확인하고 처음 참인 분기만 실행합니다.',
      code: lesson.code,
      flow: lesson.flow,
      output: '합격',
    ),
  ];
}
