import 'package:dio/dio.dart';

import 'auth_test_support.dart';

const stamp = '2026-10-12T01:00:00Z';
Map<String, dynamic> serverTemplate() => {
  'id': 31,
  'categoryId': 201,
  'languageId': 101,
  'title': '서버 조건문',
  'summary': '실제 응답 모양',
  'description': '본문 설명',
  'difficulty': 'EASY',
  'published': true,
  'media': <dynamic>[],
  'sections': [
    {
      'id': 311,
      'parentId': null,
      'title': '첫 목차',
      'body': '서버 본문',
      'exampleCode': 'if (true) {}',
      'media': <dynamic>[],
      'children': <dynamic>[],
    },
  ],
};
Map<String, dynamic> serverQuestion(int id) => {
  'id': id,
  'categoryId': 203,
  'languageId': 101,
  'prompt': '서버 문제 $id',
  'relatedTemplateId': 31,
  'relatedSectionId': 311,
  'difficulty': 'NORMAL',
  'passScore': 70,
  'published': true,
  'media': <dynamic>[],
  'questionType': id == 41
      ? 'MULTIPLE_CHOICE'
      : id == 42
      ? 'CODE_WRITING'
      : 'CODE_EXPLANATION',
  'choiceOptions': id == 41
      ? [
          {'key': 'A', 'text': '첫 선택'},
          {'key': 'B', 'text': '두 번째'},
        ]
      : null,
  'explanation': '서버 해설',
};

class LearningServer extends TestAuthAdapter {
  LearningServer() {
    handle = respond;
  }
  int? failure;
  String? failurePath;
  final saved = <int, Map<String, dynamic>>{};
  Map<String, dynamic>? savedProgress;
  bool bookmarked = false;
  int nextId = 1;
  Future<ResponseBody> respond(RequestOptions r) async {
    if (failure != null && (failurePath == null || failurePath == r.path)) {
      return jsonResponse({}, failure!);
    }
    if (r.path == '/api/auth/login') return jsonResponse(testTokens(), 200);
    if (r.path == '/api/languages') {
      return jsonResponse([
        {'id': 101, 'code': 'JAVA', 'name': 'Java'},
      ], 200);
    }
    if (r.path == '/api/categories') {
      return jsonResponse([
        {
          'id': 201,
          'parentId': null,
          'code': 'GRAMMAR',
          'name': '문법',
          'children': [],
        },
        {
          'id': 202,
          'parentId': null,
          'code': 'PRACTICAL',
          'name': '실무',
          'children': [
            {
              'id': 204,
              'parentId': 202,
              'code': 'PRACTICAL_CACHE',
              'name': '캐시',
              'children': [],
            },
          ],
        },
        {
          'id': 203,
          'parentId': null,
          'code': 'CODING_PROBLEM',
          'name': '문제',
          'children': [],
        },
      ], 200);
    }
    if (r.path == '/api/templates') {
      return jsonResponse([
        serverTemplate()
          ..remove('sections')
          ..remove('description'),
      ], 200);
    }
    if (r.path == '/api/templates/31') {
      return jsonResponse(serverTemplate(), 200);
    }
    if (r.path == '/api/questions') {
      return jsonResponse([
        for (final id in [41, 42, 43]) serverQuestion(id),
      ], 200);
    }
    if (RegExp(r'^/api/questions/\d+$').hasMatch(r.path)) {
      return jsonResponse(
        serverQuestion(int.parse(r.path.split('/').last)),
        200,
      );
    }
    if (r.path == '/api/users/me/progress') {
      return jsonResponse([if (savedProgress != null) savedProgress], 200);
    }
    if (r.path.endsWith('/bookmarks')) {
      return jsonResponse([
        if (bookmarked) {'userId': 1, 'templateId': 31},
      ], 200);
    }
    if (r.path.contains('/bookmarks/templates/')) {
      bookmarked = r.method == 'PUT';
      return jsonResponse(
        bookmarked ? {'userId': 1, 'templateId': 31} : null,
        bookmarked ? 200 : 204,
      );
    }
    if (r.path.contains('/progress/templates/')) {
      final data = r.data as Map;
      savedProgress = {
        'userId': 1,
        'templateId': 31,
        'lastSectionId': data['lastSectionId'],
        'startedAt': stamp,
        'lastStudiedAt': stamp,
        'completedAt': data['completed'] == null
            ? (savedProgress == null ? null : savedProgress!['completedAt'])
            : data['completed'] == true
            ? stamp
            : null,
      };
      return jsonResponse(savedProgress, 200);
    }
    if (r.path.contains('/submissions')) {
      final id = int.parse(r.path.split('/')[3]);
      if (r.method == 'POST') {
        final data = r.data as Map;
        saved[id] = {
          'id': nextId++,
          'userId': data['userId'],
          'questionId': id,
          ...data,
          'gradingStatus': id == 41 ? 'COMPLETED' : 'PENDING',
          'gradingMethod': id == 41 ? 'DB' : null,
          'score': id == 41
              ? (data['selectedChoiceKey'] == 'B' ? 100 : 0)
              : null,
          'feedback': null,
          'submittedAt': stamp,
          'gradedAt': id == 41 ? stamp : null,
        };
        return jsonResponse(saved[id], 201);
      }
      return jsonResponse(saved[id], saved.containsKey(id) ? 200 : 404);
    }
    return jsonResponse({}, 404);
  }
}
