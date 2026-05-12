import 'package:flutter/material.dart';

import '../../../shared/widgets/responsive_container.dart';

class ChatMessage {
  final String role;
  final String content;

  ChatMessage({
    required this.role,
    required this.content,
  });
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isRecording = false;

  final List<ChatMessage> _messages = [
    ChatMessage(
      role: 'assistant',
      content: '왔니. 하고 싶은 말 있으면 천천히 말해봐.',
    ),
  ];

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _controller.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages.add(
          ChatMessage(
            role: 'assistant',
            content: '우리 수연이, 그렇게 말해줘서 고맙다. 천천히 이야기해도 괜찮아.',
          ),
        );
        _isLoading = false;
      });

      _scrollToBottom();
    });
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveContainer(
        child: Column(
          children: [
            const _PersonaHeader(),
            const _ScreenLabel(),
            Expanded(
              child: _ChatMessageList(
                messages: _messages,
                isLoading: _isLoading,
                scrollController: _scrollController,
              ),
            ),
            _ChatInputBar(
              controller: _controller,
              isLoading: _isLoading,
              isRecording: _isRecording,
              onSend: _sendMessage,
              onVoiceTap: _toggleRecording,
            ),
            const _FooterInfo(),
          ],
        ),
      ),
    );
  }
}

class _PersonaHeader extends StatelessWidget {
  const _PersonaHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE6E6E6)),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: Color(0xFFE1E1E1),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '할머니',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '기록 기반 AI 페르소나',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF777777),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Text(
              '가족 내부 테스트 · 기록 기반 AI 페르소나',
              style: TextStyle(
                fontSize: 17,
                color: Color(0xFF555555),
              ),
            ),
          ),
          const SizedBox(width: 28),
          const Text(
            'Dev',
            style: TextStyle(
              fontSize: 18,
              decoration: TextDecoration.underline,
              color: Color(0xFF8A8A8A),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenLabel extends StatelessWidget {
  const _ScreenLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      alignment: Alignment.centerLeft,
      color: const Color(0xFFFAFAFA),
      child: const Text(
        'S-01 통합 대화 · 텍스트 + Push-to-talk',
        style: TextStyle(
          fontSize: 17,
          color: Color(0xFFA0A0A0),
        ),
      ),
    );
  }
}

class _ChatMessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isLoading;
  final ScrollController scrollController;

  const _ChatMessageList({
    required this.messages,
    required this.isLoading,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAFAFA),
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 36),
        itemCount: messages.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == messages.length && isLoading) {
            return const _AssistantBubble(
              text: '할머니가 생각하고 있어요...',
              isLoading: true,
            );
          }

          final message = messages[index];
          final isUser = message.role == 'user';

          if (isUser) {
            return _UserBubble(text: message.content);
          }

          return _AssistantBubble(text: message.content);
        },
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  final String text;
  final bool isLoading;

  const _AssistantBubble({
    required this.text,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 22,
            height: 1.45,
            color:
                isLoading ? const Color(0xFF999999) : const Color(0xFF222222),
          ),
        ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;

  const _UserBubble({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
        decoration: BoxDecoration(
          color: const Color(0xFF2B2B2B),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 22,
            height: 1.45,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final bool isRecording;
  final VoidCallback onSend;
  final VoidCallback onVoiceTap;

  const _ChatInputBar({
    required this.controller,
    required this.isLoading,
    required this.isRecording,
    required this.onSend,
    required this.onVoiceTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE3E3E3)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !isLoading,
                  minLines: 1,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 21),
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: '할머니한테 하고 싶은 말을 적어보세요.',
                    hintStyle: const TextStyle(
                      color: Color(0xFF999999),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 22,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFD7D7D7)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFF333333)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                height: 78,
                width: 150,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onSend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF252525),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFCCCCCC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '보내기',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 78,
                width: 184,
                child: ElevatedButton(
                  onPressed: onVoiceTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRecording
                        ? const Color(0xFFB94343)
                        : const Color(0xFF454545),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isRecording ? '● 듣는 중' : '● 말하기',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            '구체적인 사실은 기억에 근거가 있을 때만 답하도록 설계되어 있어요.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF7A7A7A),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterInfo extends StatelessWidget {
  const _FooterInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(
          top: BorderSide(color: Color(0xFFE5E5E5)),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          Text(
            '비공개 링크 테스트 · anonymous_session_id 기준으로 사용 기록 저장',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }
}
