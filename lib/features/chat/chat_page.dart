import 'package:flutter/material.dart';

import '../../../shared/widgets/responsive_container.dart';

class ChatMessage {
  final String id;
  final String role;
  final String content;
  final bool isLoading;
  final bool feedbackSubmitted;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.isLoading = false,
    this.feedbackSubmitted = false,
  });

  ChatMessage copyWith({
    String? id,
    String? role,
    String? content,
    bool? isLoading,
    bool? feedbackSubmitted,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      isLoading: isLoading ?? this.isLoading,
      feedbackSubmitted: feedbackSubmitted ?? this.feedbackSubmitted,
    );
  }
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
  bool _isPreparingResponse = false;

  final List<ChatMessage> _messages = [
    ChatMessage(
      id: 'init',
      role: 'assistant',
      content: '왔니. 하고 싶은 말 있으면 천천히 말해봐.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: 'user',
          content: text,
        ),
      );
      _controller.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
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
    if (_isPreparingResponse) return;

    if (!_isRecording) {
      setState(() {
        _isRecording = true;
      });

      return;
    }

    // 녹음 종료
    setState(() {
      _isRecording = false;
      _isPreparingResponse = true;
    });

    // mock transcript
    const transcript = '할머니 오늘 너무 힘들었어';

    _messages.add(
      ChatMessage(
        id: DateTime.now().toString(),
        role: 'user',
        content: transcript,
      ),
    );

    // loading bubble
    _messages.add(
      ChatMessage(
        id: 'loading',
        role: 'assistant',
        content: '할머니가 말하는 중...',
        isLoading: true,
      ),
    );

    _scrollToBottom();

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _messages.removeWhere((m) => m.id == 'loading');

        _messages.add(
          ChatMessage(
            id: DateTime.now().toString(),
            role: 'assistant',
            content: '우리 수연이 오늘 많이 힘들었구나. 너무 혼자 견디려고 하지 말고 천천히 이야기해도 괜찮아.',
          ),
        );

        _isPreparingResponse = false;
      });

      _scrollToBottom();
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
              isPreparingResponse: _isPreparingResponse,
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
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '기록 기반 AI 페르소나',
                  style: TextStyle(
                    fontSize: 15,
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
                fontSize: 15,
                color: Color(0xFF555555),
              ),
            ),
          ),
          // const SizedBox(width: 28),
          // const Text(
          //   'Dev',
          //   style: TextStyle(
          //     fontSize: 15,
          //     decoration: TextDecoration.underline,
          //     color: Color(0xFF8A8A8A),
          //   ),
          // ),
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
            return _AssistantBubble(
              message: ChatMessage(
                id: 'text-loading',
                role: 'assistant',
                content: '할머니가 생각하고 있어요...',
                isLoading: true,
              ),
            );
          }

          final message = messages[index];
          final isUser = message.role == 'user';

          if (isUser) {
            return _UserBubble(text: message.content);
          }

          return _AssistantBubble(message: message);
        },
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  final ChatMessage message;

  const _AssistantBubble({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 560),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFFE0E0E0),
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 17,
                height: 1.45,
                color: message.isLoading
                    ? const Color(0xFF999999)
                    : const Color(0xFF222222),
              ),
            ),
          ),

          // feedback buttons
          if (!message.isLoading)
            Padding(
              padding: const EdgeInsets.only(
                left: 8,
                bottom: 24,
              ),
              child: Row(
                children: [
                  _FeedbackChip(
                    label: '좋았어요',
                    icon: Icons.thumb_up_alt_outlined,
                    onTap: () {},
                  ),
                  const SizedBox(width: 10),
                  _FeedbackChip(
                    label: '아쉬워요',
                    icon: Icons.thumb_down_alt_outlined,
                    onTap: () {},
                  ),
                  const SizedBox(width: 10),
                  _FeedbackTextButton(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => const _FeedbackModal(),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
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
            fontSize: 17,
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
  final bool isPreparingResponse;

  const _ChatInputBar({
    required this.controller,
    required this.isLoading,
    required this.isRecording,
    required this.isPreparingResponse,
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
                  style: const TextStyle(fontSize: 16),
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
                height: 65,
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
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 65,
                width: 184,
                child: ElevatedButton(
                  onPressed: isPreparingResponse ? null : onVoiceTap,
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
                    isPreparingResponse
                        ? '답변 준비 중...'
                        : isRecording
                            ? '● 듣는 중'
                            : '● 말하기',
                    style: const TextStyle(
                      fontSize: 18,
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
              fontSize: 13,
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
              fontSize: 12,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _FeedbackChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: const Color(0xFFDADADA),
          ),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: const Color(0xFF666666),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackTextButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FeedbackTextButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: ButtonStyle(
        overlayColor: WidgetStateProperty.all(
          Colors.transparent,
        ),
        splashFactory: NoSplash.splashFactory,
        padding: WidgetStateProperty.all(
          EdgeInsets.zero,
        ),
        minimumSize: WidgetStateProperty.all(
          Size.zero,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text(
        '피드백 남기기',
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF777777),
          decoration: TextDecoration.underline,
          decorationColor: Color(0xFF777777),
        ),
      ),
    );
  }
}

class _FeedbackModal extends StatefulWidget {
  const _FeedbackModal();

  @override
  State<_FeedbackModal> createState() => _FeedbackModalState();
}

class _FeedbackModalState extends State<_FeedbackModal> {
  final TextEditingController _controller = TextEditingController();

  String _selectedRating = '좋았어요';

  final Set<String> _selectedTags = {
    '위로가 됐어요',
    '기억에 없는 말을 지어냈어요',
  };

  final List<String> _ratings = [
    '좋았어요',
    '보통이에요',
    '아쉬웠어요',
  ];

  final List<String> _tags = [
    '할머니 같았어요',
    '위로가 됐어요',
    '말투가 어색해요',
    '사실이 틀렸어요',
    '기억에 없는 말을 지어냈어요',
    '목소리가 어색해요',
    '섬뜩하거나 불편했어요',
    '기타',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  void _submitFeedback() {
    final feedback = {
      'rating': _selectedRating,
      'tags': _selectedTags.toList(),
      'comment': _controller.text.trim(),
    };

    debugPrint('feedback: $feedback');

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('피드백이 저장되었습니다.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 760,
        ),
        child: Container(
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '이 답변은 어땠나요?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: _ratings.map((rating) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 18),
                        child: _RatingButton(
                          label: rating,
                          selected: _selectedRating == rating,
                          onTap: () {
                            setState(() {
                              _selectedRating = rating;
                            });
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),
                const Text(
                  '구체적으로 선택해주세요',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF555555),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 14,
                  children: _tags.map((tag) {
                    final selected = _selectedTags.contains(tag);
                    return _FeedbackTagChip(
                      label: tag,
                      selected: selected,
                      onTap: () => _toggleTag(tag),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),
                const Text(
                  '구체적인 의견을 남겨주세요',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF555555),
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _controller,
                  minLines: 5,
                  maxLines: 8,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: '더 자세한 피드백을 남겨주시면 도움이 됩니다...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9A9A9A),
                    ),
                    contentPadding: const EdgeInsets.all(24),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFFDADADA),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFF222222),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 38),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFB9D8FF),
                    ),
                  ),
                  child: const Text(
                    '이 피드백은 대표/개발팀의 기억 DB 보강 검토 대상으로 저장됩니다.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2454B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 42),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 65,
                        child: ElevatedButton(
                          onPressed: _submitFeedback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF252525),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            '제출하기',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: SizedBox(
                        height: 65,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF222222),
                            side: const BorderSide(
                              color: Color(0xFFDADADA),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            '닫기',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPositive = label == '좋았어요';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 65,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? isPositive
                  ? const Color(0xFFF0FFF6)
                  : const Color(0xFFF5F5F5)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? isPositive
                    ? const Color(0xFF2ECC71)
                    : const Color(0xFF222222)
                : const Color(0xFFDADADA),
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: selected
                ? isPositive
                    ? const Color(0xFF098B3E)
                    : const Color(0xFF222222)
                : const Color(0xFF222222),
          ),
        ),
      ),
    );
  }
}

class _FeedbackTagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FeedbackTagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF252525) : const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF444444),
          ),
        ),
      ),
    );
  }
}
