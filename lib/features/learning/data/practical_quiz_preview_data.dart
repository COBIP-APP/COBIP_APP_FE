// Local examples for rehearsing the practical lesson flow before API integration.
const practicalQuizSamples = [
  (
    templateId: 201,
    prompt: '캐시에서 요청한 데이터를 찾지 못했을 때 일반적인 처리 흐름은 무엇인가요?',
    choices: ['항상 오류를 반환한다.', '원본 DB에서 조회한 뒤 캐시에 저장한다.', '임의의 값을 반환한다.'],
    answer: 'B',
    explanation: 'Cache Miss가 발생하면 원본에서 데이터를 조회하고 이후 요청을 위해 캐시에 저장할 수 있습니다.',
  ),
  (
    templateId: 201,
    prompt: '캐시의 TTL은 무엇을 의미하나요?',
    choices: ['캐시의 만료까지 남은 시간', 'DB 테이블의 행 수', '사용자 비밀번호의 길이'],
    answer: 'A',
    explanation: 'TTL은 캐시의 유효 시간입니다. 변경 빈도와 오래된 데이터를 허용할 수 있는 범위를 고려해 설정합니다.',
  ),
  (
    templateId: 201,
    prompt: '여러 캐시가 동시에 만료되어 원본 DB에 요청이 몰릴 때 고려할 방법은 무엇인가요?',
    choices: [
      '모든 캐시의 만료 시각을 같게 맞춘다.',
      '원본 DB 조회를 영구적으로 막는다.',
      '캐시 만료 시간을 분산한다.',
    ],
    answer: 'C',
    explanation: '만료 시간을 분산하면 같은 순간에 Cache Miss가 집중되는 현상을 줄일 수 있습니다.',
  ),
  (
    templateId: 202,
    prompt: 'DB 인덱스의 주된 역할은 무엇인가요?',
    choices: ['필요한 행을 찾는 탐색 비용을 줄인다.', '모든 데이터를 암호화한다.', '트랜잭션을 없앤다.'],
    answer: 'A',
    explanation: '인덱스는 조회에 활용하는 별도의 자료구조입니다. 조건에 맞는 행을 효율적으로 찾도록 돕습니다.',
  ),
  (
    templateId: 202,
    prompt: '인덱스를 추가할 때 함께 고려해야 할 비용은 무엇인가요?',
    choices: [
      '아무 비용도 발생하지 않는다.',
      '저장 공간과 데이터 변경 시 인덱스 갱신 비용',
      '모든 조회가 반드시 느려지는 비용',
    ],
    answer: 'B',
    explanation: '인덱스는 저장 공간을 사용하며 INSERT·UPDATE·DELETE에 따른 갱신 비용도 발생할 수 있습니다.',
  ),
  (
    templateId: 202,
    prompt: '쿼리의 조회 경로를 살펴보는 데 유용한 정보는 무엇인가요?',
    choices: ['사용자의 화면 밝기', '서버의 파일 이름', '쿼리 실행 계획'],
    answer: 'C',
    explanation: '실행 계획으로 테이블 접근 방식과 인덱스 사용 여부 등을 확인하고 개선 방향을 검토합니다.',
  ),
  (
    templateId: 203,
    prompt: 'HTTP 5xx 상태 코드는 일반적으로 어느 쪽의 오류를 나타내나요?',
    choices: ['서버 측 오류', '정상 응답', '요청한 데이터의 개수'],
    answer: 'A',
    explanation: '5xx는 서버 측 오류를 나타냅니다. 상태 코드와 응답 내용, 서버 로그를 함께 확인합니다.',
  ),
  (
    templateId: 203,
    prompt: 'DNS의 기본 역할은 무엇인가요?',
    choices: ['응답 본문을 압축한다.', '도메인 이름을 IP 주소로 해석한다.', 'DB 인덱스를 생성한다.'],
    answer: 'B',
    explanation:
        'DNS는 도메인 이름을 IP 주소로 해석하는 데 사용됩니다. 이름 해석 오류와 연결 오류를 구분해서 확인합니다.',
  ),
  (
    templateId: 203,
    prompt: '네트워크 요청의 타임아웃을 설정하는 이유는 무엇인가요?',
    choices: ['모든 요청을 성공시키기 위해', '응답 데이터를 삭제하기 위해', '응답을 무한정 기다리지 않도록 하기 위해'],
    answer: 'C',
    explanation:
        '타임아웃은 대기 시간을 제한합니다. 실패를 감지한 뒤 재시도나 사용자 안내 같은 후속 처리를 할 수 있습니다.',
  ),
  (
    templateId: 204,
    prompt: '상세한 진단 정보를 남길 때 주로 사용하는 로그 레벨은 무엇인가요?',
    choices: ['DEBUG', '항상 ERROR', '로그 레벨과 무관하다.'],
    answer: 'A',
    explanation: 'DEBUG는 상세 진단 정보에 사용합니다. 운영 환경에서는 로그 양과 민감 정보 포함 여부도 고려합니다.',
  ),
  (
    templateId: 204,
    prompt: '여러 로그에서 같은 요청의 흐름을 추적하려면 무엇이 도움이 되나요?',
    choices: ['매 줄의 시각을 삭제한다.', '요청 식별자를 함께 기록한다.', '로그를 무작위 순서로 섞는다.'],
    answer: 'B',
    explanation: '요청 식별자를 공통으로 기록하면 같은 요청에 속한 로그를 모아 흐름을 추적할 수 있습니다.',
  ),
  (
    templateId: 204,
    prompt: '로그에 그대로 남기지 않아야 할 정보는 무엇인가요?',
    choices: ['발생 시각', '로그 레벨', '비밀번호와 인증 토큰'],
    answer: 'C',
    explanation: '비밀번호와 인증 토큰 등 민감 정보는 로그에서 제외하거나 적절히 마스킹해야 합니다.',
  ),
];
