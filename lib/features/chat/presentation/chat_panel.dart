import '../../../app/widgets/learning_ui.dart';
import '../../../app/app_ui_tokens.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'chat_view_model.dart';

Future<void> showChatPanel(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: AppColors.background,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  builder: (context) => const ChatPanel(),
);

class ChatPanel extends StatefulWidget {
  const ChatPanel({super.key, this.isPage = false});
  final bool isPage;
  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  late final _input = TextEditingController(
    text: context.read<ChatViewModel>().draft,
  );
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    if (mounted && _scroll.hasClients) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }
  }

  void _send() {
    if (_input.text.trim().isEmpty) return;
    context.read<ChatViewModel>().send(_input.text);
    _input.clear();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  @override
  Widget build(BuildContext context) {
    final messages = context.watch<ChatViewModel>().messages;
    final media = MediaQuery.of(context);
    final available =
        (media.size.height - media.viewInsets.bottom - media.padding.top - 48)
            .clamp(160.0, media.size.height);
    return LearningTheme(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: widget.isPage ? 0 : media.viewInsets.bottom,
        ),
        child: SizedBox(
          height: widget.isPage
              ? null
              : (media.size.height * .72).clamp(160.0, available),
          child: SafeArea(
            top: false,
            child: LearningBody(
              child: Column(
                children: [
                  if (!widget.isPage)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.smart_toy_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'COBIA 챗봇',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            tooltip: '챗봇 닫기',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '더미 응답 · 대화는 앱 실행 중에만 유지됩니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return Align(
                          alignment: message.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  (media.size.width > 560
                                      ? 560
                                      : media.size.width) *
                                  .82,
                            ),
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: message.isUser
                                  ? AppColors.primary
                                  : Colors.white,
                              border: Border.all(
                                color: message.isUser
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(
                                  message.isUser ? 16 : 4,
                                ),
                                bottomRight: Radius.circular(
                                  message.isUser ? 4 : 16,
                                ),
                              ),
                            ),
                            child: SelectableText(
                              message.text,
                              style: TextStyle(
                                color: message.isUser
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            key: const ValueKey('chat-input'),
                            controller: _input,
                            minLines: 1,
                            maxLines: 3,
                            maxLength: 1000,
                            onChanged: (value) {
                              context.read<ChatViewModel>().draft = value;
                              setState(() {});
                            },
                            decoration: const InputDecoration(
                              hintText: '메시지를 입력하세요',
                              labelText: '메시지',
                              counterText: '',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          tooltip: '메시지 보내기',
                          style: IconButton.styleFrom(
                            minimumSize: const Size(52, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadii.control,
                              ),
                            ),
                          ),
                          onPressed: _input.text.trim().isEmpty ? null : _send,
                          icon: const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isPage)
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('학습 계속하기'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
