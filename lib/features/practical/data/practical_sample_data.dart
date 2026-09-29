class PracticalChapter {
  const PracticalChapter(
    this.id,
    this.title,
    this.summary,
    this.points,
    this.code,
    this.explanation,
  );
  final String id;
  final String title;
  final String summary;
  final List<String> points;
  final String code;
  final String explanation;
}

class PracticalTopic {
  const PracticalTopic(
    this.id,
    this.category,
    this.title,
    this.summary,
    this.tags,
    this.chapters,
  );
  final String id;
  final String category;
  final String title;
  final String summary;
  final List<String> tags;
  final List<PracticalChapter> chapters;

  static PracticalTopic? fromId(String? id) {
    for (final topic in practicalTopics) {
      if (topic.id == id) return topic;
    }
    return null;
  }
}

// 서버 연결 전 화면 탐색에 사용하는 샘플 콘텐츠입니다.
const practicalTopics = [
  PracticalTopic(
    'cache',
    '캐시',
    '캐시 관리와 Redis 활용',
    '반복 조회를 줄이고 빠르게 응답하는 캐시 전략을 알아보세요.',
    ['Cache', 'Redis', 'TTL'],
    [
      PracticalChapter(
        'basics',
        '캐시 기본 개념',
        '자주 사용하는 데이터를 가까운 곳에 보관해요.',
        [
          '조회가 잦고 변경이 적은 데이터부터 캐시 적용을 검토합니다.',
          '캐시에 데이터가 있으면 Hit, 없으면 Miss라고 부릅니다.',
          '캐시는 원본과 일시적으로 다를 수 있으므로 허용 가능한 지연을 정합니다.',
        ],
        '요청 → 캐시 조회\nHit  → 캐시 데이터 반환\nMiss → DB 조회 → 캐시 저장 → 반환',
        '상품 상세 정보를 반복 조회하는 상황을 가정한 흐름입니다. 캐시가 없으면 원본 DB에서 읽습니다.',
      ),
      PracticalChapter(
        'redis',
        'Redis 활용',
        '키와 값으로 데이터를 저장하고 조회해요.',
        ['데이터 종류와 식별자가 드러나도록 키 이름을 정합니다.', '조회 결과가 없을 때 원본을 읽는 경로도 준비합니다.'],
        'SET product:42 "keyboard"\nGET product:42',
        'product:42라는 키에 문자열을 저장한 뒤 같은 키로 조회합니다. 명령은 화면 예시이며 실행되지 않습니다.',
      ),
      PracticalChapter(
        'ttl',
        'TTL 설정',
        '캐시 데이터의 유효 시간을 정해요.',
        [
          'TTL은 캐시가 만료될 때까지의 시간입니다.',
          '변경 빈도와 허용 가능한 오래된 데이터의 범위를 고려합니다.',
          '동시 만료로 요청이 몰리지 않도록 만료 시간을 분산할 수 있습니다.',
        ],
        'SET product:42 "keyboard" EX 60\nTTL product:42',
        '60초 뒤 만료되는 예시입니다. TTL 조회 값은 시간이 지나면서 줄어듭니다.',
      ),
      PracticalChapter(
        'invalidation',
        '캐시 무효화',
        '원본이 변경되면 오래된 캐시를 정리해요.',
        [
          'Cache Aside는 애플리케이션이 캐시와 원본 조회를 관리하는 방식입니다.',
          '원본을 갱신한 뒤 해당 캐시를 삭제하는 방식을 사용할 수 있습니다.',
          '동시 요청이나 삭제 실패에 대한 처리는 별도로 고려해야 합니다.',
        ],
        '1. DB 상품 정보 수정\n2. DEL product:42\n3. 다음 조회에서 DB 값을 캐시에 저장',
        '삭제 후 첫 조회는 Miss가 되어 원본을 읽습니다. 실제 서비스에서는 경쟁 조건과 실패 재시도도 설계합니다.',
      ),
    ],
  ),
  PracticalTopic(
    'database',
    'DB',
    'DB 인덱스와 쿼리 최적화',
    '인덱스와 실행 계획으로 조회 과정을 이해해보세요.',
    ['DB', 'Index', 'SQL'],
    [
      PracticalChapter(
        'index',
        '인덱스 기본 개념',
        '필요한 행을 찾는 탐색 비용을 줄여요.',
        [
          '인덱스는 조회를 돕는 별도의 자료구조입니다.',
          '조건과 정렬에 자주 쓰는 컬럼을 검토합니다.',
          '저장 공간과 쓰기 비용이 추가되므로 모든 컬럼에 만들지는 않습니다.',
        ],
        'CREATE INDEX idx_users_email\nON users (email);',
        '이메일로 사용자를 찾는 요청이 많은 상황을 가정합니다.',
      ),
      PracticalChapter(
        'plan',
        '실행 계획 읽기',
        'DB가 데이터를 찾는 방법을 살펴봐요.',
        ['실행 계획에서 스캔 방법과 예상 행 수를 확인합니다.', '작은 테이블에서는 전체 스캔이 더 유리할 수도 있습니다.'],
        "EXPLAIN SELECT id FROM users\nWHERE email = 'sample@example.com';",
        '이 예시는 PostgreSQL 문법입니다. 실제 실행 계획은 데이터 분포와 통계에 따라 달라집니다.',
      ),
      PracticalChapter(
        'query',
        '조회 범위 줄이기',
        '필요한 컬럼과 행만 요청해요.',
        [
          '필요한 컬럼을 명시해 전송량을 줄입니다.',
          '조건과 정렬 기준을 함께 검토합니다.',
          '개선 전후의 실제 성능을 비교합니다.',
        ],
        'SELECT id, name FROM users\nWHERE id > 100\nORDER BY id\nLIMIT 20;',
        '마지막으로 본 ID 이후의 데이터 20개를 가져오는 페이지 조회 예시입니다.',
      ),
    ],
  ),
  PracticalTopic(
    'network',
    '네트워크',
    '네트워크 장애 분석',
    'HTTP 응답과 연결 흐름으로 장애 원인을 좁혀보세요.',
    ['Network', 'HTTP', 'DNS'],
    [
      PracticalChapter(
        'http',
        'HTTP 응답 이해',
        '요청과 응답의 상태를 확인해요.',
        ['상태 코드와 응답 본문을 함께 확인합니다.', '4xx는 요청 관련 문제, 5xx는 서버 측 오류를 나타냅니다.'],
        'HTTP/1.1 200 OK\nContent-Type: application/json\n\n{"message": "ok"}',
        '성공 응답의 형식을 보여주는 샘플입니다. 실제 요청을 보내지 않습니다.',
      ),
      PracticalChapter(
        'dns',
        'DNS와 연결 확인',
        '이름 조회부터 서버 연결까지 나누어 확인해요.',
        ['DNS는 도메인 이름에 대응하는 주소를 찾습니다.', '이름 조회 성공과 서버 연결 성공은 서로 다른 단계입니다.'],
        '도메인 조회 → 서버 연결\n→ TLS 연결 → HTTP 요청 → 응답',
        '문제가 발생한 단계를 먼저 찾으면 확인할 설정과 로그의 범위를 줄일 수 있습니다.',
      ),
      PracticalChapter(
        'timeout',
        '타임아웃과 재시도',
        '응답을 무한정 기다리지 않도록 해요.',
        [
          '연결 대기와 응답 대기 시간을 구분합니다.',
          '재시도 횟수와 간격을 제한합니다.',
          '결제처럼 중복 실행이 위험한 요청은 멱등성 보장 없이 재시도하지 않습니다.',
        ],
        '첫 요청 실패\n→ 잠시 대기 → 재시도\n→ 제한 횟수 초과 시 오류 안내',
        '일시적인 장애의 재시도 흐름입니다. 모든 오류가 재시도로 해결되는 것은 아닙니다.',
      ),
    ],
  ),
  PracticalTopic(
    'logging',
    '로그',
    '로그 관리와 모니터링',
    '기록을 남기고 서비스 상태를 파악하는 방법을 알아보세요.',
    ['Log', 'Monitoring', 'Observability'],
    [
      PracticalChapter(
        'levels',
        '로그 레벨',
        '기록의 목적에 따라 중요도를 나눠요.',
        [
          'DEBUG는 상세 진단, INFO는 주요 흐름을 기록합니다.',
          'WARN과 ERROR는 주의하거나 실패한 상황을 구분합니다.',
          '비밀번호와 토큰 같은 민감한 값은 기록하지 않습니다.',
        ],
        'INFO  request completed\nWARN  slow response detected\nERROR database connection failed',
        '로그 수준별 메시지 예시입니다. 실제 서비스 로그를 가져오지 않습니다.',
      ),
      PracticalChapter(
        'structured',
        '구조화된 로그',
        '같은 형식으로 기록해 검색을 쉽게 해요.',
        ['시간, 수준, 요청 식별자 등 공통 필드를 정합니다.', '요청 ID로 여러 단계의 기록을 연결합니다.'],
        '{\n  "level": "INFO",\n  "requestId": "demo-001",\n  "durationMs": 120\n}',
        '요청 처리 시간을 JSON 형태로 기록한 샘플입니다.',
      ),
      PracticalChapter(
        'monitoring',
        '모니터링 지표',
        '개별 로그와 전체 지표를 함께 살펴봐요.',
        [
          '요청량, 오류율, 응답 시간을 함께 확인합니다.',
          '평균뿐 아니라 느린 요청의 분포도 확인합니다.',
          '알림은 대응할 수 있는 기준으로 설정합니다.',
        ],
        '요청 수: 1,000\n오류 수: 10\n오류율: 1%',
        '설명을 위한 가상 수치입니다. 앱의 실제 사용량이나 학습 현황이 아닙니다.',
      ),
    ],
  ),
];
