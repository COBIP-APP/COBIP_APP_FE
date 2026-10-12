import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../problems/data/ai_api.dart';
import 'chat_view_model.dart';

/// In-memory conversations owned by the app, not by an individual route/sheet.
class ChatSessions extends ChangeNotifier {
  ChatSessions({required this.api});
  final AiApi api;
  static const mainKey = 'main';
  static String templateKey(int templateId) => 'template:$templateId';

  final _conversations = <String, ChatViewModel>{};
  int? _userId;
  int _generation = 0;
  int get generation => _generation;
  bool _disposed = false;

  ChatViewModel conversation(String key) => _conversations.putIfAbsent(
    key,
    () => ChatViewModel(api: api)..bindUser(_userId),
  );

  void bindUser(int? userId) {
    if (_disposed || _userId == userId) return;
    _userId = userId;
    final generation = ++_generation;
    // Reset live models too: an open sheet may still hold one during logout.
    for (final chat in _conversations.values) {
      chat.bindUser(userId);
    }
    scheduleMicrotask(() {
      if (!_disposed && generation == _generation) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    for (final chat in _conversations.values) {
      chat.dispose();
    }
    _conversations.clear();
    super.dispose();
  }
}
