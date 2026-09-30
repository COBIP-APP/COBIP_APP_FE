const chatWelcome = '안녕하세요! COBIP 학습 도우미예요. 궁금한 개념을 물어보세요.';

String sampleChatReply(String message) {
  final query = message.toLowerCase();
  if (query.contains('for') || query.contains('반복')) {
    return '반복문은 같은 작업을 여러 번 수행할 때 사용해요. 시작값, 반복 조건, 값의 변화를 차례로 살펴보세요. 예를 들어 1부터 3까지 더하면 1 + 2 + 3 = 6이 됩니다.';
  }
  if (query.contains('조건') || query.contains('if')) {
    return 'if는 조건이 참일 때 코드를 실행해요. else는 조건이 거짓일 때 실행됩니다. 먼저 조건식의 결과를 확인하고 실행되는 분기를 따라가 보세요.';
  }
  if (query.contains('캐시') || query.contains('redis')) {
    return '캐시는 자주 읽는 데이터를 보관해서 반복 조회 비용을 줄여요. Redis에 값을 저장하고 TTL로 유효 시간을 정할 수 있어요. 원본이 바뀌면 오래된 캐시를 어떻게 갱신할지도 생각해보세요.';
  }
  return '지금은 미리 준비한 답변을 보여주는 데모예요. “반복문”, “조건문”, “캐시”에 대해 질문해보세요. 입력한 코드나 문제를 실제 AI가 분석하지는 않습니다.';
}
