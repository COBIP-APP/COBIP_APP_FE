import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../problems/data/ai_api.dart';
import '../../problems/data/ai_models.dart';

class ChatMessage {
  const ChatMessage(this.text, {this.isUser = false, this.reply});
  final String text;
  final bool isUser;
  final AiChatReply? reply;
}

class ChatViewModel extends ChangeNotifier {
  ChatViewModel({required this.api});
  final AiApi api;
  static const _welcome = ChatMessage('안녕하세요! COBIA 학습 도우미예요. 궁금한 개념을 물어보세요.');
  final List<ChatMessage> _messages = [_welcome];
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String draft = '';
  String? _error;
  String? get error => _error;
  bool _busy = false;
  bool get busy => _busy;
  bool _disposed = false;
  int? _userId;
  int _generation = 0;
  CancelToken _cancel = CancelToken();
  String? _failedMessage;

  void bindUser(int? userId) {
    if (userId == _userId) return;
    _userId = userId;
    final generation = ++_generation;
    _cancel.cancel();
    _cancel = CancelToken();
    _messages
      ..clear()
      ..add(_welcome);
    draft = '';
    _error = null;
    _failedMessage = null;
    _busy = false;
    scheduleMicrotask(() {
      if (!_disposed && generation == _generation) notifyListeners();
    });
  }

  Future<void> send(String text) async {
    final value = text.trim();
    if (_busy || _disposed || value.isEmpty) return;
    _messages.add(ChatMessage(value, isUser: true));
    draft = '';
    await _request(value);
  }

  Future<void> retry() async {
    if (_busy || _disposed || _failedMessage == null) return;
    await _request(_failedMessage!);
  }

  Future<void> _request(String message) async {
    final generation = _generation;
    _busy = true;
    _error = null;
    _failedMessage = null;
    notifyListeners();
    try {
      final reply = await api.chat(message, cancelToken: _cancel);
      if (_disposed || generation != _generation) return;
      if (reply.fallback) {
        _error = 'AI 답변을 생성하지 못했어요. 잠시 후 다시 시도해 주세요.';
        _failedMessage = message;
      } else {
        _messages.add(ChatMessage(reply.answer, reply: reply));
      }
    } catch (e) {
      if (_disposed || generation != _generation) return;
      _error = e is AiApiException ? e.message : '답변을 받지 못했어요. 다시 시도해 주세요.';
      _failedMessage = message;
    } finally {
      if (!_disposed && generation == _generation) {
        _busy = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _cancel.cancel();
    super.dispose();
  }
}
