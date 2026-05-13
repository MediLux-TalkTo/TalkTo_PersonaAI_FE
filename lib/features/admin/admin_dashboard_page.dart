import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              _AdminHeader(
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _SectionTitle('주요 메트릭'),
                      SizedBox(height: 20),
                      _MetricGrid(),
                      SizedBox(height: 48),
                      _SectionTitle('부정 피드백 큐'),
                      SizedBox(height: 20),
                      _NegativeFeedbackGrid(),
                      SizedBox(height: 48),
                      _SectionTitle('피드백 검토'),
                      SizedBox(height: 20),
                      _ReviewList(),
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
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 28),
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
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '개발자 통계/피드백 페이지',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '⚠ 내부 개발자 확인용 · 가족 사용자에게 노출하지 않음',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFFCC5A00),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 56,
            child: OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 20),
              label: const Text(
                '대화 화면으로',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF222222),
                side: const BorderSide(color: Color(0xFFD8D8D8)),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Color(0xFF222222),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid();

  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('28', '총 접속 세션'),
      ('24', '총 대화 세션'),
      ('142', '총 사용자 메시지'),
      ('138', '총 AI 답변'),
      ('34', 'Push-to-talk 시도'),
      ('31', '음성 응답 완료'),
      ('76%', '긍정 피드백 비율'),
      ('24%', '부정 피드백 비율'),
      ('8.8%', 'STT 실패율'),
      ('3.2%', 'TTS 실패율'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 1 : 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 20,
            mainAxisExtent: 76,
          ),
          itemBuilder: (context, index) {
            final item = metrics[index];
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE1E1E1)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF777777),
            ),
          ),
        ],
      ),
    );
  }
}

class _NegativeFeedbackGrid extends StatelessWidget {
  const _NegativeFeedbackGrid();

  @override
  Widget build(BuildContext context) {
    final items = [
      ('8건', '사실이 틀렸어요'),
      ('5건', '기억에 없는 말을 지어냈어요'),
      ('3건', '섬뜩하거나 불편했어요'),
      ('4건', '목소리가 어색해요'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 1 : 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 20,
            mainAxisExtent: 76,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _NegativeFeedbackCard(
              count: item.$1,
              label: item.$2,
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD40000),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFFD40000),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewList extends StatelessWidget {
  const _ReviewList();

  @override
  Widget build(BuildContext context) {
    final reviews = [
      _ReviewItemData(
        tag: '사실이 틀렸어요',
        message: '할머니는 이 표현을 자주 쓰지 않았어요.',
        user: 'anonymous_session_01',
        time: '2026-05-13 13:20',
      ),
      _ReviewItemData(
        tag: '기억에 없는 말을 지어냈어요',
        message: '실제로 없던 가족 여행 이야기가 나왔습니다.',
        user: 'anonymous_session_02',
        time: '2026-05-13 13:05',
      ),
      _ReviewItemData(
        tag: '목소리가 어색해요',
        message: '말투는 괜찮았지만 음성이 조금 부자연스러웠습니다.',
        user: 'anonymous_session_03',
        time: '2026-05-13 12:52',
      ),
    ];

    return Column(
      children: reviews.map((review) {
        return _ReviewItem(review);
      }).toList(),
    );
  }
}

class _ReviewItemData {
  final String tag;
  final String message;
  final String user;
  final String time;

  _ReviewItemData({
    required this.tag,
    required this.message,
    required this.user,
    required this.time,
  });
}

class _ReviewItem extends StatelessWidget {
  final _ReviewItemData data;

  const _ReviewItem(this.data);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE1E1E1)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.tag,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFFD40000),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.message,
            style: const TextStyle(
              fontSize: 17,
              color: Color(0xFF222222),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${data.user} · ${data.time}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }
}
