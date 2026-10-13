// 화면 확인용 임시 데이터입니다. 서버 연동 시 이 파일의 데이터를 교체합니다.
enum GrammarLanguage {
  java('java', 'Java'),
  python('python', 'Python'),
  javascript('javascript', 'JavaScript');

  const GrammarLanguage(this.id, this.label);
  final String id;
  final String label;
}
