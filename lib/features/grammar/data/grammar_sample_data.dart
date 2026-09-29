// 화면 확인용 임시 데이터입니다. 서버 연동 시 이 파일의 데이터를 교체합니다.
enum GrammarLanguage {
  java('java', 'Java'),
  python('python', 'Python'),
  javascript('javascript', 'JavaScript');

  const GrammarLanguage(this.id, this.label);
  final String id;
  final String label;

  static GrammarLanguage? fromId(String id) {
    for (final language in values) {
      if (language.id == id) return language;
    }
    return null;
  }
}

enum GrammarCategory {
  basics('기초'),
  control('제어문'),
  objects('객체지향'),
  collections('컬렉션');

  const GrammarCategory(this.label);
  final String label;
}

class GrammarChapter {
  const GrammarChapter({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.progress,
  });

  final String id;
  final String title;
  final String description;
  final GrammarCategory category;
  final double progress;

  String get status => progress == 1
      ? '완료'
      : progress == 0
      ? '미시작'
      : '학습 중';
}

const sampleDailyGoal = 5;
const sampleDailyCompleted = 2;

const grammarSampleChapters = <GrammarLanguage, List<GrammarChapter>>{
  GrammarLanguage.java: [
    GrammarChapter(
      id: 'variables',
      title: '변수와 자료형',
      description: 'int, double, boolean과 String으로 값을 표현해요.',
      category: GrammarCategory.basics,
      progress: .6,
    ),
    GrammarChapter(
      id: 'conditions',
      title: '조건문',
      description: 'if, else, switch로 실행 흐름을 선택해요.',
      category: GrammarCategory.control,
      progress: 1,
    ),
    GrammarChapter(
      id: 'loops',
      title: '반복문',
      description: 'for와 while로 반복 작업을 처리해요.',
      category: GrammarCategory.control,
      progress: .4,
    ),
    GrammarChapter(
      id: 'arrays',
      title: '배열',
      description: '같은 자료형의 여러 값을 함께 관리해요.',
      category: GrammarCategory.basics,
      progress: 0,
    ),
    GrammarChapter(
      id: 'classes',
      title: '클래스와 객체',
      description: '클래스를 정의하고 객체를 생성해요.',
      category: GrammarCategory.objects,
      progress: 0,
    ),
    GrammarChapter(
      id: 'lists',
      title: 'List와 Map',
      description: '컬렉션으로 데이터를 저장하고 찾아요.',
      category: GrammarCategory.collections,
      progress: 0,
    ),
  ],
  GrammarLanguage.python: [
    GrammarChapter(
      id: 'variables',
      title: '변수와 자료형',
      description: '숫자, 문자열, 불리언으로 값을 표현해요.',
      category: GrammarCategory.basics,
      progress: .7,
    ),
    GrammarChapter(
      id: 'conditions',
      title: '조건문',
      description: 'if, elif, else로 조건을 나눠요.',
      category: GrammarCategory.control,
      progress: 0,
    ),
    GrammarChapter(
      id: 'loops',
      title: '반복문',
      description: 'for, range, while로 반복해요.',
      category: GrammarCategory.control,
      progress: 0,
    ),
    GrammarChapter(
      id: 'classes',
      title: '클래스와 객체',
      description: 'class와 생성자로 객체를 만들어요.',
      category: GrammarCategory.objects,
      progress: 0,
    ),
    GrammarChapter(
      id: 'lists',
      title: '리스트와 딕셔너리',
      description: '여러 값과 키·값 쌍을 관리해요.',
      category: GrammarCategory.collections,
      progress: 0,
    ),
  ],
  GrammarLanguage.javascript: [
    GrammarChapter(
      id: 'variables',
      title: '변수와 자료형',
      description: 'let과 const로 변수를 선언해요.',
      category: GrammarCategory.basics,
      progress: 0,
    ),
    GrammarChapter(
      id: 'conditions',
      title: '조건문',
      description: 'if와 switch로 조건에 따라 실행해요.',
      category: GrammarCategory.control,
      progress: 0,
    ),
    GrammarChapter(
      id: 'loops',
      title: '반복문',
      description: 'for와 while로 코드를 반복 실행해요.',
      category: GrammarCategory.control,
      progress: 0,
    ),
    GrammarChapter(
      id: 'classes',
      title: '클래스와 객체',
      description: '객체의 속성과 메서드를 알아봐요.',
      category: GrammarCategory.objects,
      progress: 0,
    ),
    GrammarChapter(
      id: 'collections',
      title: '배열과 Map',
      description: '배열과 Map으로 여러 값을 다뤄요.',
      category: GrammarCategory.collections,
      progress: 0,
    ),
  ],
};
