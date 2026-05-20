import '../../../core/network/api_client.dart';

class AdminApi {
  Future<AdminMetrics> getMetrics() async {
    final response = await ApiClient.dio.get('/admin/metrics/overview');
    final data = response.data['data'];

    if (data == null) {
      throw Exception('admin metrics data가 없습니다.');
    }

    return AdminMetrics.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<NegativeFeedbackSummary>> getNegativeSummary() async {
    final response =
        await ApiClient.dio.get('/admin/feedback/negative-summary');
    final data = response.data['data'];

    if (data == null) {
      return [];
    }

    return (data as List)
        .map((e) => NegativeFeedbackSummary.fromJson(
              Map<String, dynamic>.from(e),
            ))
        .toList();
  }

  Future<List<FeedbackReview>> getFeedbackReviews() async {
    final response = await ApiClient.dio.get('/admin/feedback/reviews');
    final data = response.data['data'];

    if (data == null) {
      return [];
    }

    return (data as List)
        .map((e) => FeedbackReview.fromJson(
              Map<String, dynamic>.from(e),
            ))
        .toList();
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

class NegativeFeedbackSummary {
  final String tag;
  final int count;

  NegativeFeedbackSummary({
    required this.tag,
    required this.count,
  });

  factory NegativeFeedbackSummary.fromJson(Map<String, dynamic> json) {
    return NegativeFeedbackSummary(
      tag: json['tag'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class FeedbackReview {
  final String time;
  final String sessionId;
  final String rating;
  final List<String> tags;
  final String comment;

  FeedbackReview({
    required this.time,
    required this.sessionId,
    required this.rating,
    required this.tags,
    required this.comment,
  });

  factory FeedbackReview.fromJson(Map<String, dynamic> json) {
    return FeedbackReview(
      time: json['time'] ?? json['createdAt'] ?? '',
      sessionId: json['sessionId'] ?? '',
      rating: json['rating'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      comment: json['comment'] ?? '-',
    );
  }
}
