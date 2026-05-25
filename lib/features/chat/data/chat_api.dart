import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
        'content': message,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> sendVoiceMessage({
    required String conversationId,
    required String audioPath,
    String? personaId,
    String? sttText,
  }) async {
    final MultipartFile audioFile;

    if (kIsWeb && audioPath.startsWith('blob:')) {
      final blobResponse = await Dio().get<List<int>>(
        audioPath,
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      final bytes = blobResponse.data;

      if (bytes == null || bytes.isEmpty) {
        throw Exception('녹음 파일 bytes를 읽지 못했습니다.');
      }

      audioFile = MultipartFile.fromBytes(
        bytes,
        filename: 'voice_${DateTime.now().millisecondsSinceEpoch}.wav',
      );
    } else {
      audioFile = await MultipartFile.fromFile(
        audioPath,
        filename: audioPath.split('/').last,
      );
    }

    final formData = FormData.fromMap({
      'audio_file': audioFile,
      if (personaId != null) 'personaId': personaId,
      if (sttText != null && sttText.isNotEmpty) 'sttText': sttText,
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

  Future<Map<String, dynamic>> submitFeedback({
    required String messageId,
    required String rating,
    required List<String> tags,
    required String comment,
  }) async {
    final response = await ApiClient.dio.post(
      '/messages/$messageId/feedback',
      data: {
        'rating': rating,
        'tags': tags,
        'comment': comment,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> getActivePersona() async {
    final response = await ApiClient.dio.get('/personas/active');
    return Map<String, dynamic>.from(response.data);
  }
}
