import 'package:flutter/foundation.dart';

import '../data/chat_sample_data.dart';

class ChatMessage {
  const ChatMessage(this.text, {this.isUser = false});
  final String text;
  final bool isUser;
}

class ChatViewModel extends ChangeNotifier {
  final List<ChatMessage> _messages = [const ChatMessage(chatWelcome)];
  String draft = '';
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  void send(String text) {
    final value = text.trim();
    if (value.isEmpty) return;
    _messages.add(ChatMessage(value, isUser: true));
    _messages.add(ChatMessage(sampleChatReply(value)));
    draft = '';
    notifyListeners();
  }
}
