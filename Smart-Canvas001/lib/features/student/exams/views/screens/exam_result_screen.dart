import 'package:flutter/material.dart';
import 'package:smart_canvas/features/professor/exams/models/exam_submission_model.dart';
import 'package:easy_localization/easy_localization.dart';

class ExamResultScreen extends StatefulWidget {
  final ExamSubmissionModel submission;

  const ExamResultScreen({super.key, required this.submission});

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnim = CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sub = widget.submission;
    final percentage = sub.percentage;
    final passed = percentage >= 50;
    final gradeLabel = sub.gradeLabel;

    final mainColor = passed ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final gradColors = passed
        ? [const Color(0xFF10B981), const Color(0xFF059669)]
        : [const Color(0xFFEF4444), const Color(0xFFDC2626)];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFF1F5F9),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Material(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(Icons.close_rounded, size: 22,
                            color: isDark ? Colors.white54 : Colors.black54),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('exam_results_title'.tr(), style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      )),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ──── SCORE CIRCLE ────
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: mainColor.withValues(alpha: 0.2),
                        blurRadius: 40, spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _ScorePainter(
                      progress: percentage / 100,
                      color: mainColor,
                      bgColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(gradeLabel, style: TextStyle(
                            fontSize: 44, fontWeight: FontWeight.w900,
                            color: mainColor,
                          )),
                          Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white38 : Colors.black38,
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ──── STATUS BADGE ────
              FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradColors),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: mainColor.withValues(alpha: 0.3),
                        blurRadius: 16, offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(passed ? Icons.celebration_rounded : Icons.sentiment_dissatisfied,
                        color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(passed ? 'passed_msg'.tr() : 'not_passed_msg'.tr(),
                        style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800,
                          fontSize: 17, letterSpacing: 0.3,
                        )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ──── STATS GRID ────
              FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          icon: Icons.star_rounded,
                          label: 'score_lbl'.tr(),
                          value: sub.score.toStringAsFixed(1),
                          color: const Color(0xFFF59E0B),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          icon: Icons.flag_rounded,
                          label: 'total_lbl'.tr(),
                          value: '${sub.totalPoints}',
                          color: const Color(0xFF2ECC71),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          icon: Icons.percent_rounded,
                          label: 'percentage_lbl'.tr(),
                          value: '${percentage.toStringAsFixed(0)}%',
                          color: mainColor,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ──── EXAM INFO ────
              FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1B15) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 12, offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sub.examTitle ?? 'Exam', style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        )),
                        if (sub.submittedAt != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded, size: 14,
                                color: isDark ? Colors.white38 : Colors.black38),
                              const SizedBox(width: 6),
                              Text('submitted_lbl'.tr(), style: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black38,
                              )),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ──── BACK BUTTON ────
              FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity, height: 54,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2ECC71), Color(0xFF8B5CF6)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2ECC71).withValues(alpha: 0.35),
                            blurRadius: 16, offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.home_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text('back_to_dashboard'.tr(), style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16,
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
          )),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            fontSize: 11, color: isDark ? Colors.white38 : Colors.black38,
          )),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  SCORE CIRCLE PAINTER
// ════════════════════════════════════════════════════════════════

class _ScorePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _ScorePainter({required this.progress, required this.color, required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 12.0;

    // Background
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = bgColor,
    );

    final gradient = SweepGradient(
      startAngle: -1.5708,
      endAngle: 4.7124,
      colors: [color.withValues(alpha: 0.2), color],
    );

    // Progress
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -1.5708,
      2 * 3.14159 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = gradient.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
