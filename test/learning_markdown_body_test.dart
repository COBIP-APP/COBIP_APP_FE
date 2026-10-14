import 'package:cobip_app_fe/app/app_ui_tokens.dart';
import 'package:cobip_app_fe/app/widgets/learning_ui.dart';
import 'package:cobip_app_fe/features/learning/presentation/learning_markdown_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'section_flow_test_support.dart';

const _sample = '''## 캐시 적용 기준

자주 조회하고 변경이 드문 데이터는 **캐시**를 고려할 수 있습니다.

- 조회 빈도가 높음
- 빠른 응답이 필요함

> 데이터 갱신 시점도 함께 고려합니다.

만료 시간은 `TTL`로 설정합니다.''';

class _MarkdownServer extends SectionServer {
  _MarkdownServer({required super.practical, this.body = _sample});
  final String? body;

  @override
  Map<String, dynamic> get template => super.template
    ..['sections'] = [
      {
        'id': 300,
        'title': '1. 개요',
        'body': body,
        'media': [],
        'children': [
          {...super.sections.first, 'parentId': 300, 'body': body},
        ],
      },
    ];
}

TextStyle _renderedStyle(WidgetTester tester, String text) {
  TextStyle? search(InlineSpan span, TextStyle inherited) {
    final effective = inherited.merge(span.style);
    if (span is TextSpan) {
      if (span.text == text) return effective;
      for (final child in span.children ?? <InlineSpan>[]) {
        final found = search(child, effective);
        if (found != null) return found;
      }
    }
    return null;
  }

  return tester
      .widgetList<RichText>(find.byType(RichText))
      .map((widget) => search(widget.text, const TextStyle()))
      .whereType<TextStyle>()
      .first;
}

Future<void> _openBody(WidgetTester tester, String body) => tester.pumpWidget(
  MaterialApp(
    theme: appUiTheme,
    home: Scaffold(body: ListView(children: [LearningMarkdownBody(body)])),
  ),
);

void main() {
  testWidgets('제목·강조·목록·인용·인라인 코드를 앱 스타일로 표시한다', (tester) async {
    await _openBody(tester, '# 학습 제목\n\n$_sample\n\n### 확인 순서\n\n1. 조회\n2. 갱신');
    expect(_renderedStyle(tester, '학습 제목').fontSize, 24);
    expect(_renderedStyle(tester, '캐시 적용 기준').fontSize, 20);
    expect(_renderedStyle(tester, '확인 순서').fontSize, 16);
    expect(_renderedStyle(tester, '캐시').fontWeight, FontWeight.w700);
    expect(_renderedStyle(tester, 'TTL').fontFamily, 'monospace');
    expect(
      _renderedStyle(tester, 'TTL').backgroundColor,
      AppColors.primarySoft,
    );
    expect(
      _renderedStyle(tester, '데이터 갱신 시점도 함께 고려합니다.').color,
      AppColors.textSecondary,
    );
    expect(find.text('조회 빈도가 높음'), findsOneWidget);
    expect(find.text('빠른 응답이 필요함'), findsOneWidget);
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('2.'), findsOneWidget);
    expect(find.textContaining('**'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('기존 일반 텍스트의 줄바꿈과 빈 본문을 유지한다', (tester) async {
    await _openBody(tester, '첫 번째 줄\n두 번째 줄\n\n다음 문단');
    expect(find.text('첫 번째 줄\n두 번째 줄'), findsOneWidget);
    expect(find.text('다음 문단'), findsOneWidget);
    await _openBody(tester, ' \n\t ');
    expect(find.byType(MarkdownBody), findsNothing);
  });

  testWidgets('Markdown 이미지와 HTML은 실행하거나 이미지로 로드하지 않는다', (tester) async {
    await _openBody(tester, '''![원격](https://example.invalid/image.png)
![로컬](file:///image.png)
![에셋](resource:image.png)

<img src="https://example.invalid/html.png">

<script>alert('test')</script>

본문 끝''');
    expect(find.byType(Image), findsNothing);
    expect(find.text('본문 끝'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final practical in [false, true]) {
    final path = practical
        ? '/practical/204/templates/31'
        : '/grammar/java/chapters/31';
    testWidgets('${practical ? '실무' : '문법'} API 본문과 하위 목차에 적용하고 예제 코드를 유지한다', (
      tester,
    ) async {
      await openSectionApp(tester, _MarkdownServer(practical: practical), path);
      expect(find.text('캐시 적용 기준'), findsOneWidget);
      expect(find.byType(LearningCode), findsNothing);
      await tester.tap(find.byTooltip('목차'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('section-311')));
      await tester.pumpAndSettle();
      expect(find.text('캐시 적용 기준'), findsOneWidget);
      await reveal(tester, find.byType(LearningCode));
      expect(find.text('int value = 311;'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('긴 본문은 작은 화면과 큰 글자에서도 학습 화면 스크롤로 읽는다', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openSectionApp(
      tester,
      _MarkdownServer(practical: true, body: '$_sample\n\n' * 5),
      '/practical/204/templates/31',
    );
    expect(find.byType(Scrollable), findsOneWidget);
    expect(tester.takeException(), isNull);
    final next = find.byKey(const ValueKey('lesson-next'));
    await reveal(tester, next);
    expect(next.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('본문이 공백뿐이면 Markdown 표시를 생략한다', (tester) async {
    await openSectionApp(
      tester,
      _MarkdownServer(practical: false, body: ' \n '),
      '/grammar/java/chapters/31',
    );
    expect(find.byType(LearningMarkdownBody), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
