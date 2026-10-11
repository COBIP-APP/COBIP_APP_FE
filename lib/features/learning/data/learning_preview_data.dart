import '../../grammar/data/condition_lesson_data.dart';
import '../../grammar/data/condition_quiz_data.dart';
import '../../grammar/data/grammar_sample_data.dart';
import '../../practical/data/practical_sample_data.dart';
import '../../problems/data/problem_sample_data.dart';
import 'learning_models.dart';
import 'practical_quiz_preview_data.dart';

// Existing authored sample text is adapted into the BE template/section shape.
// IDs belong only to the preview. They must never be sent to the live server.
const previewLanguages = [
  LearningLanguage(1, 'JAVA', 'Java'),
  LearningLanguage(2, 'PYTHON', 'Python'),
  LearningLanguage(3, 'JAVASCRIPT', 'JavaScript'),
];
const previewCategories = [
  LearningCategory(1, 'GRAMMAR', '문법'),
  LearningCategory(2, 'PRACTICAL', '실무'),
  LearningCategory(3, 'CODING_PROBLEM', '코딩문제'),
  LearningCategory(4, 'PRACTICAL_CACHE', '캐시', parentId: 2),
  LearningCategory(5, 'PRACTICAL_DB', 'DB', parentId: 2),
  LearningCategory(6, 'PRACTICAL_NETWORK', '네트워크', parentId: 2),
  LearningCategory(7, 'PRACTICAL_LOG', '로그', parentId: 2),
];

final previewTemplates = <LearningTemplate>[
  for (final language in GrammarLanguage.values) ..._grammarTemplates(language),
  for (var i = 0; i < practicalTopics.length; i++)
    LearningTemplate(
      id: 201 + i,
      title: practicalTopics[i].title,
      summary: practicalTopics[i].summary,
      description: practicalTopics[i].summary,
      categoryId: 4 + i,
      difficulty: LearningDifficulty.normal,
      sections: [
        for (var j = 0; j < practicalTopics[i].chapters.length; j++)
          TemplateSection(
            id: (201 + i) * 100 + j + 1,
            title: practicalTopics[i].chapters[j].title,
            body:
                '${practicalTopics[i].chapters[j].summary}\n\n${practicalTopics[i].chapters[j].points.map((p) => '• $p').join('\n\n')}\n\n${practicalTopics[i].chapters[j].explanation}',
            exampleCode: practicalTopics[i].chapters[j].code,
            media: i == 0 && j == 0
                ? const [
                    LearningMedia(
                      id: 9001,
                      originalName: 'cache-flow.png',
                      objectKey: 'preview/cache-flow.png',
                      altText: '캐시 요청 흐름 참고 이미지',
                    ),
                  ]
                : const [],
          ),
      ],
    ),
];

List<LearningTemplate> _grammarTemplates(GrammarLanguage language) {
  final languageId = language.index + 1;
  final base = 100 + languageId * 10;
  final lesson = conditionLessons[language]!;
  final examples = conditionExamples(language);
  return [
    LearningTemplate(
      id: base,
      title: '변수와 자료형',
      categoryId: 1,
      languageId: languageId,
      summary: '값에 이름을 붙이고 자료형에 맞게 사용해요.',
      description: '문자열, 숫자, 참과 거짓을 구분하고 변수로 값을 다루는 방법을 알아봅니다.',
      sections: [
        TemplateSection(
          id: base * 100 + 1,
          title: '변수의 역할',
          body: '변수는 프로그램에서 사용하는 값에 이름을 붙이는 방법입니다. 같은 값을 여러 곳에서 쓰거나 나중에 바꿀 때 사용할 수 있습니다. 이름은 값의 의미를 드러내도록 정합니다.',
          exampleCode: switch (language) {
            GrammarLanguage.java => 'String name = "COBIA";\nint count = 3;\nboolean learning = true;',
            GrammarLanguage.python =>
              'name = "COBIA"\ncount = 3\nlearning = True',
            GrammarLanguage.javascript =>
              'const name = "COBIA";\nlet count = 3;\nconst learning = true;',
          },
        ),
        TemplateSection(
          id: base * 100 + 2,
          title: '자료형과 값',
          body: '숫자는 계산에, 문자열은 텍스트 표현에, 불리언은 조건 판단에 사용합니다. 숫자 3과 문자열 "3"은 서로 다른 값입니다. 연산 전에 값의 자료형을 확인하세요.',
        ),
      ],
    ),
    LearningTemplate(
      id: base + 1,
      title: '조건문',
      categoryId: 1,
      languageId: languageId,
      summary: language == GrammarLanguage.python
          ? 'if, elif, else로 실행 흐름을 선택해요.'
          : 'if, else로 실행 흐름을 선택해요.',
      description: '조건의 참과 거짓에 따라 실행할 코드를 선택하고 여러 분기를 읽는 방법을 학습합니다.',
      sections: [
        TemplateSection(
          id: (base + 1) * 100 + 1,
          title: '핵심 개념',
          body: lesson.points.map((p) => '• $p').join('\n\n'),
          exampleCode: lesson.shortCode,
        ),
        TemplateSection(
          id: (base + 1) * 100 + 2,
          title: '예제로 이해하기',
          body: '조건에 따라 실행되는 분기를 아래 목차에서 확인해 보세요.',
          children: [
            for (var i = 0; i < examples.length; i++)
              TemplateSection(
                id: (base + 1) * 100 + 3 + i,
                parentId: (base + 1) * 100 + 2,
                title: examples[i].title,
                body:
                    '${examples[i].description}\n\n${examples[i].flow.join('\n')}\n\n예상 출력: ${examples[i].output}\n코드를 실행하지 않고 설명하는 예제입니다.',
                exampleCode: examples[i].code,
              ),
          ],
        ),
      ],
    ),
    // A published template with no sections exercises the empty detail state.
    LearningTemplate(
      id: base + 2,
      title: '반복문',
      categoryId: 1,
      languageId: languageId,
      summary: '반복 작업을 간결하게 표현해요.',
      description: '목차가 아직 등록되지 않은 학습의 미리보기입니다.',
      sections: const [],
    ),
  ];
}

final previewQuestions = <LearningQuestion>[
  for (final language in GrammarLanguage.values)
    for (var i = 0; i < conditionQuestions(language).length; i++)
      LearningQuestion(
        id: 1000 + language.index * 10 + i,
        prompt: conditionQuestions(language)[i].question,
        questionType: LearningQuestionType.multipleChoice,
        categoryId: 1,
        languageId: language.index + 1,
        relatedTemplateId: 111 + language.index * 10,
        relatedSectionId: (111 + language.index * 10) * 100 + 3 + i,
        codeSnippet: conditionQuestions(language)[i].code,
        choiceOptions: [
          for (
            var j = 0;
            j < conditionQuestions(language)[i].options.length;
            j++
          )
            LearningChoice(
              String.fromCharCode(65 + j),
              conditionQuestions(language)[i].options[j],
            ),
        ],
        explanation: conditionQuestions(language)[i].explanation,
      ),
  for (var i = 0; i < practicalQuizSamples.length; i++)
    LearningQuestion(
      id: 3000 + i,
      prompt: practicalQuizSamples[i].prompt,
      questionType: LearningQuestionType.multipleChoice,
      categoryId: practicalQuizSamples[i].templateId - 197,
      relatedTemplateId: practicalQuizSamples[i].templateId,
      relatedSectionId: practicalQuizSamples[i].templateId * 100 + 1,
      choiceOptions: [
        for (var j = 0; j < practicalQuizSamples[i].choices.length; j++)
          LearningChoice(
            String.fromCharCode(65 + j),
            practicalQuizSamples[i].choices[j],
          ),
      ],
      explanation: practicalQuizSamples[i].explanation,
    ),
  for (var i = 0; i < problemMissions.length; i++) ...[
    LearningQuestion(
      id: 2000 + i * 10,
      prompt: problemMissions[i].codePrompt,
      questionType: LearningQuestionType.codeWriting,
      categoryId: 3,
      languageId: i + 1,
      difficulty: LearningDifficulty.normal,
    ),
    LearningQuestion(
      id: 2001 + i * 10,
      prompt: problemMissions[i].choicePrompt,
      questionType: LearningQuestionType.multipleChoice,
      categoryId: 3,
      languageId: i + 1,
      explanation: problemMissions[i].choiceExplanation,
      choiceOptions: [
        for (var j = 0; j < problemMissions[i].options.length; j++)
          LearningChoice(
            String.fromCharCode(65 + j),
            problemMissions[i].options[j],
          ),
      ],
    ),
    LearningQuestion(
      id: 2002 + i * 10,
      prompt: '다음 코드의 출력 결과와 그 결과가 나오는 과정을 설명하세요.',
      questionType: LearningQuestionType.codeExplanation,
      categoryId: 3,
      languageId: i + 1,
      codeSnippet: problemMissions[i].outputCode,
    ),
  ],
];

// Fake server-side answer table. Public question models expose no correct key.
final previewAnswerKeys = <int, String>{
  for (var i = 0; i < practicalQuizSamples.length; i++)
    3000 + i: practicalQuizSamples[i].answer,
  for (final language in GrammarLanguage.values)
    for (var i = 0; i < conditionQuestions(language).length; i++)
      1000 + language.index * 10 + i: String.fromCharCode(
        65 + conditionQuestions(language)[i].correctIndex,
      ),
  for (var i = 0; i < problemMissions.length; i++)
    2001 + i * 10: String.fromCharCode(65 + problemMissions[i].correctIndex),
};
