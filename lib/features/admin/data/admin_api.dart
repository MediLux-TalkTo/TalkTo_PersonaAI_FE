import '../../../core/network/api_client.dart';

class AdminApi {
  Future<AdminMetrics> getMetrics() async {
    final response = await ApiClient.dio.get('/admin/metrics/overview');

    final data = response.data['data'];

    if (data == null) {
      throw Exception('admin metrics data가 없습니다.');
    }

    return AdminMetrics.fromJson(data);
  }
}

class AdminMetrics {
  final int usersTotal;
  final int conversationsTotal;
  final int messagesTotal;
  final int voiceMessagesTotal;
  final double feedbackPositiveRatio;
  final double feedbackNegativeRatio;

  AdminMetrics({
    required this.usersTotal,
    required this.conversationsTotal,
    required this.messagesTotal,
    required this.voiceMessagesTotal,
    required this.feedbackPositiveRatio,
    required this.feedbackNegativeRatio,
  });

  factory AdminMetrics.fromJson(Map<String, dynamic> json) {
    return AdminMetrics(
      usersTotal: json['usersTotal'] ?? 0,
      conversationsTotal: json['conversationsTotal'] ?? 0,
      messagesTotal: json['messagesTotal'] ?? 0,
      voiceMessagesTotal: json['voiceMessagesTotal'] ?? 0,
      feedbackPositiveRatio:
          ((json['feedbackPositiveRatio'] ?? 0) as num).toDouble(),
      feedbackNegativeRatio:
          ((json['feedbackNegativeRatio'] ?? 0) as num).toDouble(),
    );
  }
}
