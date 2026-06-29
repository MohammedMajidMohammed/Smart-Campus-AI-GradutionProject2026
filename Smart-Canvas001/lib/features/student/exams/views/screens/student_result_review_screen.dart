import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/student/exams/view_models/cubit/student_exam_cubit.dart';

class StudentResultReviewScreen extends StatefulWidget {
  final String submissionId;
  final String examTitle;
  final double score;
  final int totalPoints;

  const StudentResultReviewScreen({
    super.key,
    required this.submissionId,
    required this.examTitle,
    required this.score,
    required this.totalPoints,
  });

  @override
  State<StudentResultReviewScreen> createState() => _StudentResultReviewScreenState();
}

class _StudentResultReviewScreenState extends State<StudentResultReviewScreen> {
  final _cubit = StudentExamCubit();
  List<Map<String, dynamic>> _answers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _answers = await _cubit.loadSubmissionReview(widget.submissionId);
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ratio = widget.totalPoints > 0 ? widget.score / widget.totalPoints : 0.0;
    final percentage = (ratio * 100).toInt();
    final isExcellent = percentage >= 85;
    final isPassed = percentage >= 50;

    // Grade-based theming
    final List<Color> headerGradient;
    final Color statusColor;
    final String gradeLabel;

    if (isExcellent) {
      headerGradient = [const Color(0xFF1E8449), const Color(0xFF9E7B1A)];
      statusColor = AppColors.kSecondaryColor;
      gradeLabel = "EXCELLENT";
    } else if (isPassed) {
      headerGradient = [const Color(0xFF1E8449), const Color(0xFF1E8449)];
      statusColor = AppColors.kPrimaryColor;
      gradeLabel = "PASSED";
    } else {
      headerGradient = [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      statusColor = const Color(0xFFEF4444);
      gradeLabel = "FAILED";
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFFAF9F5),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? const Color(0xFF1E1B15) : headerGradient[0],
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: Text(
                widget.examTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: Colors.white,
                  letterSpacing: -0.3,
                  shadows: [Shadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8)],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E1B15), const Color(0xFF0F0E0A)]
                        : headerGradient,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -50, right: -40,
                      child: Container(
                        width: 200, height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 40, left: -20,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.03),
                        ),
                      ),
                    ),
                    // Center score display
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 36),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Score ring
                            SizedBox(
                              width: 90, height: 90,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 90, height: 90,
                                    child: CircularProgressIndicator(
                                      value: ratio,
                                      strokeWidth: 7,
                                      color: Colors.white,
                                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                                      strokeCap: StrokeCap.round,
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "$percentage%",
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          height: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${widget.score.toStringAsFixed(1)}/${widget.totalPoints}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Grade badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: Text(
                                gradeLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Stats bar
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1B15) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _StatItem(
                    label: "Total",
                    value: "${_answers.length}",
                    icon: Icons.quiz_rounded,
                    color: statusColor,
                    isDark: isDark,
                  ),
                  _divider(isDark),
                  _StatItem(
                    label: "Correct",
                    value: "${_answers.where((a) => a['is_correct'] == true).length}",
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF22C55E),
                    isDark: isDark,
                  ),
                  _divider(isDark),
                  _StatItem(
                    label: "Wrong",
                    value: "${_answers.where((a) => a['is_correct'] != true).length}",
                    icon: Icons.cancel_rounded,
                    color: const Color(0xFFEF4444),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),

          // Questions header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                "Question Review",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),

          if (_isLoading)
            SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: statusColor)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final answer = _answers[index];
                    final q = answer['exam_questions'];
                    return _ReviewCard(
                      qIndex: index + 1,
                      question: q['question_text'],
                      studentAnswer: answer['student_answer'] ?? '',
                      correctAnswer: q['correct_answer'],
                      type: q['question_type'],
                      maxPoints: (q['points'] as num).toInt(),
                      earnedPoints: (answer['points_earned'] as num).toDouble(),
                      isCorrect: answer['is_correct'] as bool,
                      isDark: isDark,
                    );
                  },
                  childCount: _answers.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F0E0A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white30 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final int qIndex;
  final String question;
  final String studentAnswer;
  final String correctAnswer;
  final String type;
  final int maxPoints;
  final double earnedPoints;
  final bool isCorrect;
  final bool isDark;

  const _ReviewCard({
    required this.qIndex,
    required this.question,
    required this.studentAnswer,
    required this.correctAnswer,
    required this.type,
    required this.maxPoints,
    required this.earnedPoints,
    required this.isCorrect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isMcq = type == 'mcq';
    final isPartial = !isCorrect && earnedPoints > 0;
    
    final Color statusColor;
    final IconData icon;
    final String statusLabel;
    
    if (isCorrect) {
      statusColor = const Color(0xFF22C55E);
      icon = Icons.check_circle_rounded;
      statusLabel = "CORRECT";
    } else if (isPartial) {
      statusColor = const Color(0xFFF59E0B);
      icon = Icons.remove_circle_rounded;
      statusLabel = "PARTIAL";
    } else {
      statusColor = const Color(0xFFEF4444);
      icon = Icons.cancel_rounded;
      statusLabel = "WRONG";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: isDark ? 0.1 : 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Q$qIndex',
                    style: TextStyle(fontWeight: FontWeight.w900, color: statusColor, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    type.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(icon, size: 18, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  '${earnedPoints.toStringAsFixed(1)} / $maxPoints',
                  style: TextStyle(fontWeight: FontWeight.w900, color: statusColor, fontSize: 13),
                ),
              ],
            ),
          ),
          // Question body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                // Your answer
                _sectionLabel('YOUR ANSWER'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFFAF9F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          studentAnswer.isEmpty ? '(Not Answered)' : studentAnswer,
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isCorrect || !isMcq) ...[
                  const SizedBox(height: 16),
                  _sectionLabel(isMcq ? 'CORRECT ANSWER' : 'MODEL ANSWER'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF22C55E)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            correctAnswer,
                            style: const TextStyle(
                              color: Color(0xFF22C55E),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 10,
          color: isDark ? Colors.white24 : Colors.grey.shade400,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
