import '../../../core/network/api_client.dart';

class ChatApi {
  Future<Map<String, dynamic>> createConversation() async {
    final response = await ApiClient.dio.post(
      '/conversations',
      data: {
        'personaId': 'persona-grandma-001',
        'channel': 'TEXT',
        'title': '주말 대화',
      },
    );

    return Map<String, dynamic>.from(response.data);
  }

  Future<List<dynamic>> getConversations() async {
    final response = await ApiClient.dio.get('/conversations');
    return List<dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> getConversationDetail(
      String conversationId) async {
    final response = await ApiClient.dio.get('/conversations/$conversationId');
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> sendTextMessage({
    required String conversationId,
    required String message,
  }) async {
    final response = await ApiClient.dio.post(
      '/conversations/$conversationId/messages/text',
      data: {
        'message': message,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> sendVoiceMessage({
    required String conversationId,
    required String sttText,
  }) async {
    final response = await ApiClient.dio.post(
      '/conversations/$conversationId/messages/voice',
      data: {
        'sttText': sttText,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }

  Future<void> submitFeedback({
    required String messageId,
    required String rating,
    required List<String> tags,
    required String comment,
  }) async {
    await ApiClient.dio.post(
      '/messages/$messageId/feedback',
      data: {
        'rating': rating,
        'tags': tags,
        'comment': comment,
      },
    );
  }

  Future<List<dynamic>> getAdminFeedback() async {
    final response = await ApiClient.dio.get('/admin/feedback');
    return List<dynamic>.from(response.data);
  }
}
