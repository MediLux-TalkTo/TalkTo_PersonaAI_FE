import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class ChatApi {
  Future<Map<String, dynamic>> createConversation({
    String personaId = 'persona-grandma-001',
    String channel = 'TEXT',
    String title = '주말 대화',
  }) async {
    final response = await ApiClient.dio.post(
      '/conversations',
      data: {
        'personaId': personaId,
        'channel': channel,
        'title': title,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }

  Future<List<dynamic>> getConversations() async {
    final response = await ApiClient.dio.get('/conversations');

    final data = response.data['data'];
    if (data is List) return data;

    return [];
  }

  Future<Map<String, dynamic>> getConversationDetail(
    String conversationId,
  ) async {
    final response = await ApiClient.dio.get(
      '/conversations/$conversationId',
    );

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
    required String audioPath,
  }) async {
    final formData = FormData.fromMap({
      'audio': await MultipartFile.fromFile(
        audioPath,
        filename: audioPath.split('/').last,
      ),
    });

    final response = await ApiClient.dio.post(
      '/conversations/$conversationId/messages/voice',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
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
}
