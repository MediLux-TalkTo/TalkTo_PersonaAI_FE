import 'package:flutter/material.dart';

import '../admin/data/admin_api.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AdminApi _adminApi = AdminApi();
  late final Future<AdminMetrics> _metricsFuture;

  late final Future<List<NegativeFeedbackSummary>> _negativeSummaryFuture;
  late final Future<List<FeedbackReview>> _feedbackReviewsFuture;

  @override
  void initState() {
    super.initState();
    _metricsFuture = _adminApi.getMetrics();
    _negativeSummaryFuture = _adminApi.getNegativeSummary();
    _feedbackReviewsFuture = _adminApi.getFeedbackReviews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width < 600 ? 420 : 640,
          ),
          child: Column(
            children: [
              _AdminHeader(
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    MediaQuery.of(context).size.width < 600 ? 16 : 28,
                    MediaQuery.of(context).size.width < 600 ? 16 : 24,
                    MediaQuery.of(context).size.width < 600 ? 16 : 28,
                    MediaQuery.of(context).size.width < 600 ? 28 : 48,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('주요 메트릭'),
                      const SizedBox(height: 20),
                      FutureBuilder<AdminMetrics>(
                        future: _metricsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const _MetricLoadingBox();
                          }

                          if (snapshot.hasError) {
                            return _MetricErrorBox(
                              message: snapshot.error.toString(),
                            );
                          }

                          return _MetricGrid(
                            metrics: snapshot.data!,
                          );
                        },
                      ),
                      const SizedBox(height: 48),
                      const _SectionTitle('부정 피드백 큐'),
                      const SizedBox(height: 20),
                      FutureBuilder<List<NegativeFeedbackSummary>>(
                        future: _negativeSummaryFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const _MetricLoadingBox();
                          }

                          if (snapshot.hasError) {
                            return _MetricErrorBox(
                                message: snapshot.error.toString());
                          }

                          return _NegativeFeedbackGrid(items: snapshot.data!);
                        },
                      ),
                      const SizedBox(height: 48),
                      const _SectionTitle('피드백 검토'),
                      const SizedBox(height: 20),
                      FutureBuilder<List<FeedbackReview>>(
                        future: _feedbackReviewsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const _MetricLoadingBox();
                          }

                          if (snapshot.hasError) {
                            return _MetricErrorBox(
                                message: snapshot.error.toString());
                          }

                          return _ReviewList(reviews: snapshot.data!);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _AdminHeader({
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      height: isMobile ? 72 : 88,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFBF0),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFFFD666),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '개발자 통계/피드백 페이지',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 22,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF222222),
                  ),
                ),
                SizedBox(height: isMobile ? 4 : 8),
                Text(
                  '⚠ 내부 개발자 확인용',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 15,
                    color: const Color(0xFFCC5A00),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: isMobile ? 42 : 56,
            child: OutlinedButton.icon(
              onPressed: onBack,
              icon: Icon(
                Icons.arrow_back,
                size: isMobile ? 16 : 20,
              ),
              label: Text(
                '대화 화면',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF222222),
                side: const BorderSide(color: Color(0xFFD8D8D8)),
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    isMobile ? 12 : 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Text(
      title,
      style: TextStyle(
        fontSize: isMobile ? 18 : 24,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF222222),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final AdminMetrics metrics;

  const _MetricGrid({
    required this.metrics,
  });

  String _toPercent(double value) {
    return '${(value * 100).round()}%';
  }

  @override
  Widget build(BuildContext context) {
    final metricItems = [
      (metrics.usersTotal.toString(), '총 사용자 수'),
      (metrics.conversationsTotal.toString(), '총 대화 세션'),
      (metrics.messagesTotal.toString(), '총 메시지'),
      (metrics.voiceMessagesTotal.toString(), '음성 메시지'),
      (_toPercent(metrics.feedbackPositiveRatio), '긍정 피드백 비율'),
      (_toPercent(metrics.feedbackNegativeRatio), '부정 피드백 비율'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 480;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metricItems.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: isMobile ? 10 : 16,
            crossAxisSpacing: isMobile ? 10 : 20,
            mainAxisExtent: isMobile ? 64 : 76,
          ),
          itemBuilder: (context, index) {
            final item = metricItems[index];

            return _MetricCard(
              value: item.$1,
              label: item.$2,
            );
          },
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String value;
  final String label;

  const _MetricCard({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE1E1E1)),
        borderRadius: BorderRadius.circular(
          isMobile ? 14 : 18,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 16 : 22,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF222222),
            ),
          ),
          SizedBox(height: isMobile ? 2 : 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 9 : 10,
              color: const Color(0xFF777777),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricLoadingBox extends StatelessWidget {
  const _MetricLoadingBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE1E1E1)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        '메트릭을 불러오는 중입니다...',
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFF777777),
        ),
      ),
    );
  }
}

class _MetricErrorBox extends StatelessWidget {
  final String message;

  const _MetricErrorBox({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F2),
        border: Border.all(color: const Color(0xFFFFB8B8)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '메트릭을 불러오지 못했습니다.\n$message',
        style: const TextStyle(
          fontSize: 13,
          height: 1.5,
          color: Color(0xFFD40000),
        ),
      ),
    );
  }
}

class _NegativeFeedbackGrid extends StatelessWidget {
  final List<NegativeFeedbackSummary> items;

  const _NegativeFeedbackGrid({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 480;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: isMobile ? 10 : 16,
            crossAxisSpacing: isMobile ? 10 : 20,
            mainAxisExtent: isMobile ? 64 : 76,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _NegativeFeedbackCard(
              count: '${item.count}건',
              label: item.tag,
            );
          },
        );
      },
    );
  }
}

class _NegativeFeedbackCard extends StatelessWidget {
  final String count;
  final String label;

  const _NegativeFeedbackCard({
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F2),
        border: Border.all(color: const Color(0xFFFFB8B8)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: isMobile ? 14 : 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD40000),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 9 : 10,
              color: Color(0xFFD40000),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewList extends StatelessWidget {
  final List<FeedbackReview> reviews;

  const _ReviewList({
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (reviews.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE1E1E1)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          '아직 등록된 피드백이 없습니다.',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF777777),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: isMobile ? 720 : 640,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE1E1E1)),
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.hardEdge,
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(88),
              1: FixedColumnWidth(105),
              2: FixedColumnWidth(70),
              3: FixedColumnWidth(120),
              4: FlexColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              const TableRow(
                decoration: BoxDecoration(color: Color(0xFFFAFAFA)),
                children: [
                  _TableHeaderCell('일시'),
                  _TableHeaderCell('Session ID'),
                  _TableHeaderCell('평가'),
                  _TableHeaderCell('태그'),
                  _TableHeaderCell('코멘트'),
                ],
              ),
              ...reviews.map(
                (review) => TableRow(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFEFEFEF)),
                    ),
                  ),
                  children: [
                    _TableBodyCell(review.time),
                    _TableBodyCell(review.sessionId),
                    _RatingCell(review.rating),
                    _TagCell(review.tags),
                    _CommentCell(review.comment),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentCell extends StatelessWidget {
  final String text;

  const _CommentCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 14,
      ),
      child: Text(
        text,
        softWrap: true,
        maxLines: null,
        overflow: TextOverflow.visible,
        style: const TextStyle(
          fontSize: 12,
          height: 1.45,
          color: Color(0xFF555555),
        ),
      ),
    );
  }
}

class _ReviewItemData {
  final String time;
  final String sessionId;
  final String rating;
  final List<String> tags;
  final String comment;

  _ReviewItemData({
    required this.time,
    required this.sessionId,
    required this.rating,
    required this.tags,
    required this.comment,
  });
}

class _TableHeaderCell extends StatelessWidget {
  final String text;

  const _TableHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 14,
        vertical: isMobile ? 12 : 16,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isMobile ? 11 : 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF555555),
        ),
      ),
    );
  }
}

class _TableBodyCell extends StatelessWidget {
  final String text;

  const _TableBodyCell(this.text);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 14,
        vertical: isMobile ? 12 : 18,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          text,
          softWrap: true,
          maxLines: null,
          overflow: TextOverflow.visible,
          style: TextStyle(
            fontSize: isMobile ? 11 : 13,
            height: 1.5,
            color: Color(0xFF555555),
          ),
        ),
      ),
    );
  }
}

class _RatingCell extends StatelessWidget {
  final String rating;

  const _RatingCell(this.rating);

  @override
  Widget build(BuildContext context) {
    final isPositive = rating == '👍';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 18,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color:
                isPositive ? const Color(0xFFE8FFF0) : const Color(0xFFFFE8E8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            rating,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ),
    );
  }
}

class _TagCell extends StatelessWidget {
  final List<String> tags;

  const _TagCell(this.tags);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF444444),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
