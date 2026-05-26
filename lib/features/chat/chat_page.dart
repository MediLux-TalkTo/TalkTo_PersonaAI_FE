import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../../../shared/widgets/responsive_container.dart';
import '../admin/admin_dashboard_page.dart';
import '../chat/data/chat_api.dart';

class ChatMessage {
  final String id;
  final String role;
  final String content;
  final bool isLoading;
  final bool feedbackSubmitted;
  final String? quickFeedback;
  final bool canFeedback;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.isLoading = false,
    this.feedbackSubmitted = false,
    this.quickFeedback,
    this.canFeedback = false,
  });

  ChatMessage copyWith({
    String? id,
    String? role,
    String? content,
    bool? isLoading,
    bool? feedbackSubmitted,
    String? quickFeedback,
    bool? canFeedback,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      isLoading: isLoading ?? this.isLoading,
      feedbackSubmitted: feedbackSubmitted ?? this.feedbackSubmitted,
      quickFeedback: quickFeedback ?? this.quickFeedback,
      canFeedback: canFeedback ?? this.canFeedback,
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
  final ChatApi _chatApi = ChatApi();
  String? _conversationId;
  String? _activePersonaId;
  String _personaName = '할머니';
  String _personaDescription = '기록 기반 AI 페르소나';

  final AudioRecorder _audioRecorder = AudioRecorder();

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
  void initState() {
    super.initState();
    _loadActivePersona();
  }

  Future<void> _loadActivePersona() async {
    try {
      final response = await _chatApi.getActivePersona();
      final data = response['data'];

      if (data == null || data is! Map<String, dynamic>) return;

      if (!mounted) return;

      setState(() {
        _activePersonaId = data['id']?.toString();
        _personaName = data['displayName']?.toString() ?? '할머니';
        _personaDescription =
            data['description']?.toString() ?? '기록 기반 AI 페르소나';
      });
    } catch (e) {
      debugPrint('active persona load error: $e');
    }
  }

  Future<void> _ensureConversation() async {
    if (_conversationId != null) return;

    if (_activePersonaId == null) {
      await _loadActivePersona();
    }

    if (_activePersonaId == null) {
      throw Exception('활성 페르소나를 찾을 수 없습니다.');
    }

    final response = await _chatApi.createConversation(
      personaId: _activePersonaId!,
      channel: 'TEXT',
      title: '할머니와의 대화',
    );

    final conversationData = response['data'];

    if (conversationData == null) {
      throw Exception('conversation data가 없습니다.');
    }

    final id = conversationData['id'];

    if (id == null) {
      throw Exception('conversationId를 찾을 수 없습니다.');
    }

    _conversationId = id.toString();
  }

  Future<void> _submitQuickFeedback(String messageId, String rating) async {
    setState(() {
      final index = _messages.indexWhere((m) => m.id == messageId);

      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          quickFeedback: rating,
          feedbackSubmitted: true,
        );
      }
    });

    try {
      await _chatApi.submitFeedback(
        messageId: messageId,
        rating: rating,
        tags: const [],
        comment: '',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('피드백 저장에 실패했습니다.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
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

    try {
      await _ensureConversation();

      final response = await _chatApi.sendTextMessage(
        conversationId: _conversationId!,
        message: text,
      );

      final data = response['data'];

      if (data == null || data is! Map<String, dynamic>) {
        throw Exception('response data가 없습니다: $response');
      }

      final assistantMessage = data['assistantMessage'];

      if (assistantMessage == null ||
          assistantMessage is! Map<String, dynamic>) {
        throw Exception('assistantMessage가 없습니다: $data');
      }

      final assistantId =
          (assistantMessage['id'] ?? DateTime.now().millisecondsSinceEpoch)
              .toString();

      final assistantContent =
          (assistantMessage['content'] ?? '답변을 불러오지 못했습니다.').toString();

      setState(() {
        _messages.add(
          ChatMessage(
            id: assistantId,
            role: 'assistant',
            content: assistantContent,
            canFeedback: true,
          ),
        );
      });
    } catch (e) {
      debugPrint('sendMessage error: $e');

      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            role: 'assistant',
            content: '답변 생성에 실패했습니다. 다시 시도해주세요.',
          ),
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });

      _scrollToBottom();
    }
  }

  Future<void> _toggleRecording() async {
    if (_isPreparingResponse || _isLoading) return;

    if (!_isRecording) {
      final hasPermission = await _audioRecorder.hasPermission();

      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('마이크 권한이 필요합니다.'),
          ),
        );
        return;
      }

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.opus,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: 'talkto_voice_${DateTime.now().millisecondsSinceEpoch}.webm',
      );

      if (!mounted) return;

      setState(() {
        _isRecording = true;
      });

      return;
    }

    final path = await _audioRecorder.stop();

    setState(() {
      _isRecording = false;
      _isPreparingResponse = true;
    });

    debugPrint('recorded audio path: $path');

    if (path == null) {
      setState(() {
        _isPreparingResponse = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('녹음 파일을 생성하지 못했습니다.'),
        ),
      );
      return;
    }

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: 'user',
          content: '음성 메시지를 보냈어요.',
        ),
      );

      _messages.add(
        ChatMessage(
          id: 'voice-loading',
          role: 'assistant',
          content: '할머니가 말하는 중...',
          isLoading: true,
        ),
      );
    });

    _scrollToBottom();

    try {
      await _ensureConversation();

      debugPrint('voice POST start: $_conversationId');
      debugPrint('voice audio path: $path');
      debugPrint('voice personaId: $_activePersonaId');

      final response = await _chatApi.sendVoiceMessage(
        conversationId: _conversationId!,
        audioPath: path,
        personaId: _activePersonaId,
      );

      debugPrint('voice POST response: $response');

      final data = response['data'];

      if (data == null || data is! Map<String, dynamic>) {
        throw Exception('voice response data가 없습니다: $response');
      }

      final assistantMessage = data['assistantMessage'];

      if (assistantMessage == null ||
          assistantMessage is! Map<String, dynamic>) {
        throw Exception('voice assistantMessage가 없습니다: $data');
      }

      final assistantId =
          (assistantMessage['id'] ?? DateTime.now().millisecondsSinceEpoch)
              .toString();

      final assistantContent =
          (assistantMessage['content'] ?? '음성 답변을 불러오지 못했습니다.').toString();

      if (!mounted) return;

      setState(() {
        _messages.removeWhere((m) => m.id == 'voice-loading');

        _messages.add(
          ChatMessage(
            id: assistantId,
            role: 'assistant',
            content: assistantContent,
            canFeedback: true,
          ),
        );

        _isPreparingResponse = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.removeWhere((m) => m.id == 'voice-loading');

        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            role: 'assistant',
            content: '음성 답변 생성에 실패했습니다. 다시 시도해주세요.',
          ),
        );

        _isPreparingResponse = false;
      });
    }

    _scrollToBottom();
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
            _PersonaHeader(
              name: _personaName,
              description: _personaDescription,
            ),
            const _ScreenLabel(),
            Expanded(
              child: _ChatMessageList(
                messages: _messages,
                isLoading: _isLoading,
                scrollController: _scrollController,
                onQuickFeedback: _submitQuickFeedback,
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
            _FooterInfo(),
          ],
        ),
      ),
    );
  }
}

class _PersonaHeader extends StatelessWidget {
  final String name;
  final String description;

  const _PersonaHeader({
    required this.name,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Container(
      height: isMobile ? 82 : 118,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE6E6E6)),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isMobile ? 22 : 32,
            backgroundColor: const Color(0xFFE1E1E1),
          ),
          SizedBox(width: isMobile ? 12 : 18),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: isMobile ? 17 : 22,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF222222),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 15,
                    color: const Color(0xFF777777),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!isMobile)
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
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminDashboardPage(),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 4 : 8,
                vertical: isMobile ? 4 : 8,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              '관리자 대시보드',
              style: TextStyle(
                fontSize: isMobile ? 10 : 13,
                color: const Color(0xFF777777),
                decoration: TextDecoration.underline,
              ),
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
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Container(
      height: 20,
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
  final Future<void> Function(String messageId, String rating)? onQuickFeedback;

  _ChatMessageList({
    required this.messages,
    required this.isLoading,
    required this.scrollController,
    required this.onQuickFeedback,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Container(
      color: const Color(0xFFFAFAFA),
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 28,
          isMobile ? 12 : 20,
          isMobile ? 16 : 28,
          isMobile ? 24 : 36,
        ),
        itemCount: messages.length + (isLoading ? 1 : 0) + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const _ChatGuideText();
          }

          final messageIndex = index - 1;

          if (messageIndex == messages.length && isLoading) {
            return _AssistantBubble(
              message: ChatMessage(
                id: 'text-loading',
                role: 'assistant',
                content: '할머니가 생각하고 있어요...',
                isLoading: true,
              ),
            );
          }

          final message = messages[messageIndex];
          final isUser = message.role == 'user';

          if (isUser) {
            return _UserBubble(text: message.content);
          }

          return _AssistantBubble(
            message: message,
            onQuickFeedback: onQuickFeedback,
          );
        },
      ),
    );
  }
}

class _ChatGuideText extends StatelessWidget {
  const _ChatGuideText();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return const Padding(
      padding: EdgeInsets.only(bottom: 28),
      child: Center(
        child: Text(
          '글로 쓰거나, 오른쪽 말하기 버튼을 눌러 이야기할 수 있어요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF888888),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  final ChatMessage message;
  final Future<void> Function(String messageId, String rating)? onQuickFeedback;

  _AssistantBubble({
    required this.message,
    this.onQuickFeedback,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? width * 0.78 : 560,
            ),
            margin: const EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 22,
              vertical: isMobile ? 10 : 12,
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
                fontSize: isMobile ? 14 : 17,
                height: 1.45,
                color: message.isLoading
                    ? const Color(0xFF999999)
                    : const Color(0xFF222222),
              ),
            ),
          ),

          // feedback buttons
          if (!message.isLoading && message.canFeedback)
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
                    selected: message.quickFeedback == 'UP',
                    onTap: () => onQuickFeedback?.call(message.id, 'UP'),
                  ),
                  const SizedBox(width: 10),
                  _FeedbackChip(
                    label: '아쉬워요',
                    icon: Icons.thumb_down_alt_outlined,
                    selected: message.quickFeedback == 'DOWN',
                    onTap: () => onQuickFeedback?.call(message.id, 'DOWN'),
                  ),
                  const SizedBox(width: 10),
                  _FeedbackTextButton(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => _FeedbackModal(messageId: message.id),
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
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? width * 0.78 : 560,
        ),
        margin: const EdgeInsets.only(bottom: 18),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 32,
          vertical: isMobile ? 12 : 22,
        ),
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
  final bool isPreparingResponse;
  final VoidCallback onSend;
  final VoidCallback onVoiceTap;

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
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    Widget inputField = TextField(
      controller: controller,
      enabled: !isLoading,
      minLines: 1,
      maxLines: 4,
      style: TextStyle(fontSize: isMobile ? 14 : 16),
      onSubmitted: (_) => onSend(),
      decoration: InputDecoration(
        hintText: '할머니한테 하고 싶은 말을 적어보세요.',
        hintStyle: const TextStyle(color: Color(0xFF999999)),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 26,
          vertical: isMobile ? 14 : 22,
        ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 16 : 18),
          borderSide: const BorderSide(color: Color(0xFFD7D7D7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 16 : 18),
          borderSide: const BorderSide(color: Color(0xFF333333)),
        ),
      ),
    );

    Widget sendButton = SizedBox(
      height: isMobile ? 46 : 65,
      width: isMobile ? null : 150,
      child: ElevatedButton(
        onPressed: isLoading ? null : onSend,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF252525),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFCCCCCC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
          ),
        ),
        child: Text(
          '보내기',
          style: TextStyle(
            fontSize: isMobile ? 14 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    Widget voiceButton = SizedBox(
      height: isMobile ? 46 : 65,
      width: isMobile ? null : 184,
      child: ElevatedButton(
        onPressed: (isPreparingResponse || isLoading) ? null : onVoiceTap,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isRecording ? const Color(0xFFB94343) : const Color(0xFF454545),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
          ),
        ),
        child: Text(
          isPreparingResponse
              ? '답변 준비 중...'
              : isRecording
                  ? '● 듣는 중'
                  : '● 말하기',
          style: TextStyle(
            fontSize: isMobile ? 14 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 28,
        isMobile ? 14 : 24,
        isMobile ? 16 : 28,
        isMobile ? 12 : 18,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE3E3E3)),
        ),
      ),
      child: Column(
        children: [
          if (isMobile) ...[
            inputField,
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: sendButton),
                const SizedBox(width: 8),
                Expanded(child: voiceButton),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(child: inputField),
                const SizedBox(width: 14),
                sendButton,
                const SizedBox(width: 12),
                voiceButton,
              ],
            ),
          ],
          SizedBox(height: isMobile ? 10 : 14),
          Text(
            '구체적인 사실은 기억에 근거가 있을 때만 답하도록 설계되어 있어요.',
            style: TextStyle(
              fontSize: isMobile ? 11 : 13,
              color: const Color(0xFF7A7A7A),
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      height: isMobile ? 48 : 84,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(
          top: BorderSide(color: Color(0xFFE5E5E5)),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '비공개 링크 테스트 · anonymous_session_id 기준으로 사용 기록 저장',
          style: TextStyle(
            fontSize: isMobile ? 10 : 12,
            color: const Color(0xFF888888),
          ),
        ),
      ),
    );
  }
}

class _FeedbackChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  const _FeedbackChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

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
            color: selected ? const Color(0xFF252525) : const Color(0xFFDADADA),
          ),
          color: selected ? const Color(0xFF252525) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : const Color(0xFF666666),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: selected ? Colors.white : const Color(0xFF666666),
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
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

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
  final String messageId;

  const _FeedbackModal({
    required this.messageId,
  });

  @override
  State<_FeedbackModal> createState() => _FeedbackModalState();
}

class _FeedbackModalState extends State<_FeedbackModal> {
  final TextEditingController _controller = TextEditingController();
  final ChatApi _chatApi = ChatApi();

  String _selectedRating = '좋았어요';

  final Set<String> _selectedTags = {};

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

  String _toApiRating(String rating) {
    if (rating == '좋았어요') return 'UP';
    if (rating == '아쉬웠어요') return 'DOWN';
    return 'UP'; // 보통이에요 임시 처리
  }

  String _toApiTag(String tag) {
    switch (tag) {
      case '할머니 같았어요':
        return 'NATURAL';
      case '위로가 됐어요':
        return 'WARM';
      case '말투가 어색해요':
        return 'AWKWARD_TONE';
      case '사실이 틀렸어요':
        return 'FACTUALLY_WRONG';
      case '기억에 없는 말을 지어냈어요':
        return 'HALLUCINATION';
      case '목소리가 어색해요':
        return 'AWKWARD_VOICE';
      case '섬뜩하거나 불편했어요':
        return 'UNCOMFORTABLE';
      case '기타':
        return 'OTHER';
      default:
        return 'OTHER';
    }
  }

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

  Future<void> _submitFeedback() async {
    try {
      await _chatApi.submitFeedback(
        messageId: widget.messageId,
        rating: _toApiRating(_selectedRating),
        tags: _selectedTags.map(_toApiTag).toList(),
        comment: _controller.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('피드백이 저장되었습니다.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('피드백 저장에 실패했습니다.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? width * 0.78 : 560,
        ),
        child: Container(
          padding: const EdgeInsets.all(28),
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
                const SizedBox(height: 20),
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
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
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
                        height: 50,
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
  Color get _selectedBgColor {
    switch (label) {
      case '좋았어요':
        return const Color(0xFFEFFAF3);
      case '보통이에요':
        return const Color(0xFFF3F3F3);
      case '아쉬웠어요':
        return const Color(0xFFFFF1F1);
      default:
        return Colors.white;
    }
  }

  Color get _selectedBorderColor {
    switch (label) {
      case '좋았어요':
        return const Color(0xFF2ECC71);
      case '보통이에요':
        return const Color(0xFF9E9E9E);
      case '아쉬웠어요':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFFDADADA);
    }
  }

  Color get _selectedTextColor {
    switch (label) {
      case '좋았어요':
        return const Color(0xFF0B8F45);
      case '보통이에요':
        return const Color(0xFF555555);
      case '아쉬웠어요':
        return const Color(0xFFD93025);
      default:
        return const Color(0xFF222222);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPositive = label == '좋았어요';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _selectedBgColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _selectedBorderColor : const Color(0xFFDADADA),
            width: selected ? 1.8 : 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? _selectedTextColor : const Color(0xFF222222),
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
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
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
