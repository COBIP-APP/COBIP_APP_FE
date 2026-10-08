import '../../../app/widgets/learning_visuals.dart';
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
  backgroundColor: AppColors.surface,
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
    if (mounted &&
        _scroll.hasClients &&
        context.read<ChatViewModel>().messages.length > 1) {
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
              child: LayoutBuilder(
                builder: (context, constraints) => Column(
                  children: [
                    if (!widget.isPage)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const LearningArt('terms_robot', size: 44),
                            const SizedBox(width: 10),
                            Expanded(
                              child: constraints.maxHeight < 240
                                  ? TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('학습 계속하기'),
                                    )
                                  : const Text(
                                      'COBIA 챗봇',
                                      style: AppTypography.card,
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
                    Expanded(
                      child: ListView.builder(
                        controller: _scroll,
                        padding: AppSpacing.pagePadding(
                          context,
                          top: 12,
                        ).copyWith(bottom: 16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (index == 0) ...[
                                if (messages.length == 1) const _ChatWelcome(),
                                const LearningNotice(
                                  '더미 응답 · 대화는 앱 실행 중에만 유지됩니다.',
                                ),
                                const SizedBox(height: 20),
                              ],
                              _ChatBubble(
                                text: message.text,
                                isUser: message.isUser,
                              ),
                              if (index == 0 && messages.length == 1) ...[
                                const SizedBox(height: 16),
                                const Text(
                                  '이렇게 질문해 보세요',
                                  style: AppTypography.card,
                                ),
                                const SizedBox(height: 10),
                                for (final example in [
                                  '조건문과 반복문은 어떻게 다른가요?',
                                  '캐시는 언제 사용하나요?',
                                  '이 코드의 실행 순서가 궁금해요',
                                ])
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.chat_bubble_outline,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            example,
                                            style: AppTypography.helper,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                        ),
                      ),
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
                                hintText: '궁금한 내용을 물어보세요',
                                labelText: '메시지',
                                counterText: '',
                                fillColor: AppColors.surfaceSubtle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            tooltip: '메시지 보내기',
                            style: IconButton.styleFrom(
                              minimumSize: const Size(52, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _input.text.trim().isEmpty
                                ? null
                                : _send,
                            icon: const Icon(Icons.arrow_upward_rounded),
                          ),
                        ],
                      ),
                    ),
                    if (!widget.isPage && constraints.maxHeight >= 240)
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
      ),
    );
  }
}

class _ChatWelcome extends StatelessWidget {
  const _ChatWelcome();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 24),
    child: Column(
      children: [
        const LearningArt('terms_robot', size: 120),
        const SizedBox(height: 12),
        Text(
          '궁금할 땐,\nCOBIA',
          textAlign: TextAlign.center,
          style: AppTypography.detail.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        const Text(
          '개념부터 코드까지, 편하게 질문해 보세요.',
          textAlign: TextAlign.center,
          style: AppTypography.helper,
        ),
      ],
    ),
  );
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.text, required this.isUser});
  final String text;
  final bool isUser;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          const Row(
            children: [
              LearningArt('terms_robot', size: 28),
              SizedBox(width: 6),
              Text('COBIA', style: AppTypography.card),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: .9,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                border: Border.all(
                  color: isUser ? AppColors.primary : AppColors.border,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: SelectableText(
                text,
                style: AppTypography.body.copyWith(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
