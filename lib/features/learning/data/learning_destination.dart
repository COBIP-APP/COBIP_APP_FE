import 'package:dio/dio.dart';

import 'learning_api.dart';

typedef LearningDestination = ({
  int templateId,
  int categoryId,
  bool grammar,
  String language,
  int? sectionId,
});

Future<LearningDestination> resolveLearningDestination(
  LearningApi learning,
  int templateId,
  int? sectionId,
  CancelToken cancel,
) async {
  final template = await learning.template(templateId, cancelToken: cancel);
  final categories = await learning.categories(cancelToken: cancel);
  final grammarIds = categories
      .where((item) => item.code == 'GRAMMAR')
      .map((item) => item.id)
      .toSet();
  var added = true;
  while (added) {
    added = false;
    for (final item in categories) {
      if (grammarIds.contains(item.parentId) && grammarIds.add(item.id)) {
        added = true;
      }
    }
  }
  final grammar = grammarIds.contains(template.categoryId);
  var language = 'common';
  if (grammar && template.languageId != null) {
    final languages = await learning.languages(cancelToken: cancel);
    final match = languages.where((item) => item.id == template.languageId);
    if (match.isEmpty) {
      throw const LearningApiException('학습 언어 정보를 확인할 수 없어요.');
    }
    language = match.first.code.toLowerCase();
  }
  if (sectionId != null &&
      !template.allSections.any((item) => item.id == sectionId)) {
    throw const LearningApiException('마지막 목차가 변경되었어요. 기록을 새로고침해 주세요.');
  }
  return (
    templateId: templateId,
    categoryId: template.categoryId,
    grammar: grammar,
    language: language,
    sectionId: sectionId,
  );
}
