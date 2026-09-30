class ProblemMission {
  const ProblemMission({
    required this.id,
    required this.language,
    required this.codePrompt,
    required this.sampleCode,
    required this.choicePrompt,
    required this.options,
    required this.correctIndex,
    required this.choiceExplanation,
    required this.outputCode,
    required this.outputAnswer,
  });
  final String id;
  final String language;
  final String codePrompt;
  final String sampleCode;
  final String choicePrompt;
  final List<String> options;
  final int correctIndex;
  final String choiceExplanation;
  final String outputCode;
  final String outputAnswer;
  bool matchesSampleCode(String code) =>
      code.replaceAll('\r\n', '\n').trim() == sampleCode.trim();

  String get title => '$language 기초 미션';

  static ProblemMission? fromId(String? id) {
    for (final mission in problemMissions) {
      if (mission.id == id) return mission;
    }
    return null;
  }
}

const problemMissions = [
  ProblemMission(
    id: 'java-basics',
    language: 'Java',
    codePrompt: 'for문을 사용해 1부터 5까지 출력하세요.',
    sampleCode: 'for (int i = 1; i <= 5; i++) {\n  System.out.println(i);\n}',
    choicePrompt: 'Java 접근 제어자로 사용되지 않는 것은?',
    options: ['public', 'protected', 'private', 'free'],
    correctIndex: 3,
    choiceExplanation: 'free는 Java 접근 제어자가 아닙니다. public, protected, private를 사용할 수 있으며, 아무것도 쓰지 않으면 패키지 접근이 적용됩니다.',
    outputCode: 'int sum = 0;\nfor (int i = 1; i <= 3; i++) {\n  sum += i;\n}\nSystem.out.println(sum);',
    outputAnswer: '6',
  ),
  ProblemMission(
    id: 'python-basics',
    language: 'Python',
    codePrompt: 'for문을 사용해 1부터 5까지 출력하세요.',
    sampleCode: 'for i in range(1, 6):\n    print(i)',
    choicePrompt: 'Python에서 리스트를 만드는 표현은?',
    options: ['[1, 2, 3]', '(1, 2, 3)', '{1, 2, 3}', '"1, 2, 3"'],
    correctIndex: 0,
    choiceExplanation: '대괄호는 리스트를 만듭니다. 나머지는 순서대로 튜플, 집합, 문자열입니다.',
    outputCode:
        'total = 0\nfor i in range(1, 4):\n    total += i\nprint(total)',
    outputAnswer: '6',
  ),
  ProblemMission(
    id: 'javascript-basics',
    language: 'JavaScript',
    codePrompt: 'for문을 사용해 1부터 5까지 출력하세요.',
    sampleCode: 'for (let i = 1; i <= 5; i++) {\n  console.log(i);\n}',
    choicePrompt: '재할당할 수 있는 블록 범위 변수 선언은?',
    options: ['const', 'let', 'var', 'static'],
    correctIndex: 1,
    choiceExplanation:
        'let은 블록 범위에서 재할당 가능한 변수를 선언합니다. const는 재할당할 수 없으며 var는 블록 범위가 아닙니다.',
    outputCode: 'let sum = 0;\nfor (let i = 1; i <= 3; i++) {\n  sum += i;\n}\nconsole.log(sum);',
    outputAnswer: '6',
  ),
];
