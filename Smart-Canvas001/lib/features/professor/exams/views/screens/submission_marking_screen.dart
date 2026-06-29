import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:smart_canvas/features/professor/exams/view_models/cubit/exams_cubit.dart';

class SubmissionMarkingScreen extends StatefulWidget {
  final String submissionId;
  final String studentName;

  const SubmissionMarkingScreen({
    super.key,
    required this.submissionId,
    required this.studentName,
  });

  @override
  State<SubmissionMarkingScreen> createState() => _SubmissionMarkingScreenState();
}

class _SubmissionMarkingScreenState extends State<SubmissionMarkingScreen>
    with SingleTickerProviderStateMixin {
  final _cubit = ExamsCubit();
  List<Map<String, dynamic>> _answers = [];
  bool _isLoading = true;
  final Map<String, TextEditingController> _scoreControllers = {};
  double _totalScore = 0;
  int _maxPoints = 0;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    for (var controller in _scoreControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _answers = await _cubit.loadSubmissionAnswers(widget.submissionId);

    _totalScore = 0;
    _maxPoints = 0;

    for (var answer in _answers) {
      final q = answer['exam_questions'];
      final pointsEarned = (answer['points_earned'] as num?)?.toDouble() ?? 0;
      final maxQPoints = (q['points'] as num?)?.toInt() ?? 0;

      _totalScore += pointsEarned;
      _maxPoints += maxQPoints;

      if (q['question_type'] == 'essay') {
        _scoreControllers[answer['id']] = TextEditingController(text: pointsEarned.toString());
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _animController.forward();
    }
  }

  void _recalculateScore() {
    double tempScore = 0;
    for (var answer in _answers) {
      final q = answer['exam_questions'];
      if (q['question_type'] == 'essay') {
        final val = double.tryParse(_scoreControllers[answer['id']]?.text ?? '0') ?? 0;
        tempScore += val;
      } else {
        tempScore += (answer['points_earned'] as num?)?.toDouble() ?? 0;
      }
    }
    setState(() => _totalScore = tempScore);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentage = _maxPoints > 0 ? (_totalScore / _maxPoints) * 100 : 0.0;
    final isPassing = percentage >= 50;
    final initial = widget.studentName.isNotEmpty ? widget.studentName[0].toUpperCase() : 'S';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF0F4F8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── PREMIUM HEADER ───
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFF1E8449),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Student avatar
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withValues(alpha: 0.3), Colors.white.withValues(alpha: 0.15)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Submission Review',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0F0E0A), const Color(0xFF1E1B15)]
                        : [const Color(0xFF1E8449), const Color(0xFF2ECC71), const Color(0xFF0E6251)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: isDark ? null : const [0.0, 0.5, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(top: -80, right: -50,
                      child: Container(width: 250, height: 250,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
                    Positioned(bottom: -40, left: -30,
                      child: Container(width: 180, height: 180,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.04)))),
                    BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                      child: Container(color: Colors.transparent),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── SCORE SUMMARY CARD ───
          if (!_isLoading)
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: CurvedAnimation(parent: _animController, curve: Curves.easeOut),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1B15) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Circular progress
                        SizedBox(
                          width: 80, height: 80,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 80, height: 80,
                                child: CircularProgressIndicator(
                                  value: _maxPoints > 0 ? _totalScore / _maxPoints : 0,
                                  strokeWidth: 7,
                                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
                                  valueColor: AlwaysStoppedAnimation(isPassing ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${percentage.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Score',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isDark ? Colors.white38 : Colors.black38),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Points earned
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.stars_rounded, color: Color(0xFF2ECC71), size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Points Earned', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white54 : Colors.black45)),
                                  const Spacer(),
                                  Text(
                                    '${_totalScore.toStringAsFixed(1)} / $_maxPoints',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
                                  ),
                                ],
                              ),
                              Divider(color: isDark ? Colors.white12 : Colors.grey.shade100, height: 20),
                              // Questions count
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.quiz_rounded, color: Color(0xFF3B82F6), size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Questions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white54 : Colors.black45)),
                                  const Spacer(),
                                  Text(
                                    '${_answers.length}',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
                                  ),
                                ],
                              ),
                              Divider(color: isDark ? Colors.white12 : Colors.grey.shade100, height: 20),
                              // Status
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: (isPassing ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(isPassing ? Icons.check_circle_rounded : Icons.cancel_rounded, color: isPassing ? const Color(0xFF10B981) : const Color(0xFFEF4444), size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white54 : Colors.black45)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (isPassing ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: (isPassing ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.2)),
                                    ),
                                    child: Text(
                                      isPassing ? 'PASSED' : 'FAILED',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isPassing ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ─── SECTION HEADER ───
          if (!_isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 4, height: 22,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2ECC71), Color(0xFF1E8449)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Answer Review',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFF2ECC71).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_answers.length} Q',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isDark ? Colors.white54 : const Color(0xFF2ECC71)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ─── QUESTIONS LIST ───
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71))),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final answer = _answers[index];
                    final q = answer['exam_questions'];
                    return FadeTransition(
                      opacity: CurvedAnimation(parent: _animController, curve: Curves.easeOut),
                      child: _PremiumMarkingCard(
                        qIndex: index + 1,
                        totalQuestions: _answers.length,
                        question: q['question_text'],
                        studentAnswer: answer['student_answer'] ?? '',
                        correctAnswer: q['correct_answer'],
                        type: q['question_type'],
                        maxPoints: (q['points'] as num).toInt(),
                        currentPoints: (answer['points_earned'] as num).toDouble(),
                        isDark: isDark,
                        controller: _scoreControllers[answer['id']],
                        onChanged: (_) => _recalculateScore(),
                      ),
                    );
                  },
                  childCount: _answers.length,
                ),
              ),
            ),

          // Spacer for bottom button
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      // ─── SAVE BUTTON ───
      bottomNavigationBar: !_isLoading
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1B15) : Colors.white,
                border: Border(top: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Score summary chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: (isPassing ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: (isPassing ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPassing ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            size: 18,
                            color: isPassing ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_totalScore.toStringAsFixed(1)}/$_maxPoints',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: isPassing ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Save button
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2ECC71), Color(0xFF1E8449)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2ECC71).withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _saveGrades,
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save_rounded, size: 20, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save Grades',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _saveGrades() async {
    final grades = <String, double>{};
    for (var entry in _scoreControllers.entries) {
      grades[entry.key] = double.tryParse(entry.value.text) ?? 0;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updating grades...')));
    final success = await _cubit.updateSubmissionGrades(widget.submissionId, grades);

    if (success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grades saved successfully!')));
    }
  }
}

// ─── PREMIUM MARKING CARD ───
class _PremiumMarkingCard extends StatelessWidget {
  final int qIndex;
  final int totalQuestions;
  final String question;
  final String studentAnswer;
  final String correctAnswer;
  final String type;
  final int maxPoints;
  final double currentPoints;
  final bool isDark;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const _PremiumMarkingCard({
    required this.qIndex,
    required this.totalQuestions,
    required this.question,
    required this.studentAnswer,
    required this.correctAnswer,
    required this.type,
    required this.maxPoints,
    required this.currentPoints,
    required this.isDark,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isEssay = type == 'essay';
    final isMCQ = type == 'mcq';
    final isCorrect = isMCQ && studentAnswer.trim().toLowerCase() == correctAnswer.trim().toLowerCase();
    final accentColor = isEssay
        ? const Color(0xFF8B5CF6)
        : isCorrect
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444);
    final typeLabel = isEssay ? 'ESSAY' : 'MCQ';
    final typeIcon = isEssay ? Icons.edit_note_rounded : Icons.radio_button_checked_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── CARD HEADER ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor.withValues(alpha: 0.08), accentColor.withValues(alpha: 0.03)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: accentColor.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                // Question number badge
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Center(
                    child: Text('$qIndex', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                // Type chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(typeIcon, size: 12, color: accentColor),
                      const SizedBox(width: 4),
                      Text(typeLabel, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: accentColor, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                const Spacer(),
                // Max points
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, size: 12, color: isDark ? Colors.white38 : Colors.black38),
                      const SizedBox(width: 4),
                      Text(
                        '$maxPoints pts',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : Colors.black45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── CARD BODY ───
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question text
                Text(
                  question,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.5,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 20),

                // Student answer section
                _buildAnswerSection(
                  icon: Icons.person_rounded,
                  label: 'Student Answer',
                  content: studentAnswer,
                  bgColor: isMCQ
                      ? (isCorrect ? const Color(0xFF10B981).withValues(alpha: 0.06) : const Color(0xFFEF4444).withValues(alpha: 0.06))
                      : (isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFFAF9F5)),
                  borderColor: isMCQ
                      ? (isCorrect ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFEF4444).withValues(alpha: 0.15))
                      : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200),
                  textColor: isDark ? Colors.white : Colors.black87,
                  statusIcon: isMCQ
                      ? Icon(isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 18,
                          color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                      : null,
                ),
                const SizedBox(height: 12),

                // Correct / Reference answer
                _buildAnswerSection(
                  icon: isEssay ? Icons.menu_book_rounded : Icons.check_circle_outline_rounded,
                  label: isEssay ? 'Reference Answer' : 'Correct Answer',
                  content: correctAnswer,
                  bgColor: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF0FDF4),
                  borderColor: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFF10B981).withValues(alpha: 0.12),
                  textColor: isDark ? Colors.white70 : Colors.black54,
                ),
                const SizedBox(height: 20),

                // ─── POINTS SECTION ───
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.grading_rounded, color: Color(0xFF10B981), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Points Earned',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      if (isEssay)
                        Container(
                          width: 75,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                          ),
                          child: TextFormField(
                            controller: controller,
                            onChanged: onChanged,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF10B981), fontSize: 16),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: (isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: (isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            currentPoints.toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      Text(
                        ' / $maxPoints',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerSection({
    required IconData icon,
    required String label,
    required String content,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    Widget? statusIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: isDark ? Colors.white38 : Colors.black38),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black38,
                letterSpacing: 0.5,
              ),
            ),
            if (statusIcon != null) ...[
              const Spacer(),
              statusIcon,
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            content.isEmpty ? '(No answer provided)' : content,
            style: TextStyle(
              color: content.isEmpty ? (isDark ? Colors.white24 : Colors.black26) : textColor,
              height: 1.6,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontStyle: content.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}
