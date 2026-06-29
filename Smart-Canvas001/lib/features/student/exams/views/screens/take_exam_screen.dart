import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_canvas/features/professor/exams/models/exam_question_model.dart';
import 'package:smart_canvas/features/student/exams/view_models/cubit/student_exam_cubit.dart';
import 'package:smart_canvas/features/student/exams/views/screens/exam_result_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class TakeExamScreen extends StatefulWidget {
  final String examId;
  final String examTitle;
  final String submissionId;
  final int durationMinutes;

  const TakeExamScreen({
    super.key,
    required this.examId,
    required this.examTitle,
    required this.submissionId,
    required this.durationMinutes,
  });

  @override
  State<TakeExamScreen> createState() => _TakeExamScreenState();
}

class _TakeExamScreenState extends State<TakeExamScreen> with WidgetsBindingObserver {
  final _cubit = StudentExamCubit();
  List<ExamQuestionModel> _questions = [];
  final Map<String, String> _answers = {};
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;

  late int _remainingSeconds;
  Timer? _timer;

  // Essay controllers per question
  final Map<String, TextEditingController> _essayControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _remainingSeconds = widget.durationMinutes * 60;
    _loadQuestions();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    for (final c in _essayControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _showWarning();
    }
  }

  void _showWarning() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('warning_do_not_leave'.tr())),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadQuestions() async {
    _questions = await _cubit.loadExamQuestions(widget.examId);
    // Init essay controllers
    for (final q in _questions) {
      if (q.isEssay) {
        _essayControllers[q.id] = TextEditingController();
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _submitExam(autoSubmit: true);
        return;
      }
      if (mounted) {
        setState(() => _remainingSeconds--);
      }
    });
  }

  String get _timerText {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color get _timerColor {
    if (_remainingSeconds <= 60) return const Color(0xFFEF4444);
    if (_remainingSeconds <= 300) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  double get _timerProgress {
    final total = widget.durationMinutes * 60;
    return total > 0 ? _remainingSeconds / total : 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        _showWarning();
        return false;
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFF1F5F9),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                      ),
                      child: const SizedBox(
                        width: 32, height: 32,
                        child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF2ECC71)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('preparing_exam'.tr(), style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                    )),
                  ],
                ),
              )
            : SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(isDark),
                    _buildQuestionNavigator(isDark),
                    Expanded(child: _buildQuestionContent(isDark)),
                    _buildBottomNav(isDark),
                  ],
                ),
              ),
      ),
    );
  }

  // ──── TOP BAR ────
  Widget _buildTopBar(bool isDark) {
    final answeredCount = _answers.length;
    final progress = _questions.isNotEmpty ? answeredCount / _questions.length : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Lock badge
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lock_rounded, color: Colors.red, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.examTitle, style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('$answeredCount of ${_questions.length} ${'answered_of'.tr()}', style: TextStyle(
                      fontSize: 11, color: isDark ? Colors.white38 : Colors.black38,
                    )),
                  ],
                ),
              ),
              // Timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _timerColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _timerColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                        value: _timerProgress, strokeWidth: 2.5,
                        color: _timerColor,
                        backgroundColor: _timerColor.withValues(alpha: 0.15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_timerText, style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16, color: _timerColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
              color: const Color(0xFF2ECC71),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  // ──── QUESTION DOT NAVIGATOR ────
  Widget _buildQuestionNavigator(bool isDark) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _questions.length,
        itemBuilder: (context, i) {
          final isAnswered = _answers.containsKey(_questions[i].id);
          final isCurrent = i == _currentIndex;
          return GestureDetector(
            onTap: () => setState(() => _currentIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36, height: 36,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent
                    ? const Color(0xFF2ECC71)
                    : isAnswered
                        ? const Color(0xFF10B981)
                        : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200),
                boxShadow: isCurrent ? [
                  BoxShadow(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.3),
                    blurRadius: 8, offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Center(
                child: isAnswered && !isCurrent
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text('${i + 1}', style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: isCurrent || isAnswered
                            ? Colors.white
                            : (isDark ? Colors.white38 : Colors.black38),
                      )),
              ),
            ),
          );
        },
      ),
    );
  }

  // ──── QUESTION CONTENT ────
  Widget _buildQuestionContent(bool isDark) {
    if (_questions.isEmpty) return Center(child: Text('no_questions'.tr()));

    final question = _questions[_currentIndex];
    final selectedAnswer = _answers[question.id];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: question.isMcq
                        ? [const Color(0xFF2ECC71), const Color(0xFF8B5CF6)]
                        : [const Color(0xFFF59E0B), const Color(0xFFF97316)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Q${_currentIndex + 1}', style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14,
                )),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(question.isMcq ? 'multiple_choice'.tr() : 'essay'.tr(), style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : Colors.black38,
                )),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 13, color: Color(0xFF10B981)),
                    const SizedBox(width: 3),
                    Text('${question.points} ${'pts'.tr()}', style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10B981),
                    )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Question text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
            child: Text(question.questionText, style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.6,
            )),
          ),
          const SizedBox(height: 20),

          // MCQ options
          if (question.isMcq && question.options != null)
            ...question.options!.asMap().entries.map((entry) {
              final isSelected = selectedAnswer == entry.value;
              final letter = String.fromCharCode(65 + entry.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _answers[question.id] = entry.value),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2ECC71).withValues(alpha: 0.08)
                            : (isDark ? const Color(0xFF1E1B15) : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2ECC71)
                              : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: const Color(0xFF2ECC71).withValues(alpha: 0.12),
                            blurRadius: 10, offset: const Offset(0, 4),
                          ),
                        ] : null,
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? const Color(0xFF2ECC71)
                                  : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100),
                            ),
                            child: Center(
                              child: isSelected
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                                  : Text(letter, style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white38 : Colors.black38,
                                    )),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(entry.value, style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? const Color(0xFF2ECC71)
                                  : (isDark ? Colors.white70 : Colors.black87),
                            )),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

          // Essay input
          if (question.isEssay) ...[
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1B15) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 12, offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                maxLines: 10,
                controller: _essayControllers[question.id],
                onChanged: (v) => setState(() => _answers[question.id] = v),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.6, fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'write_answer_here'.tr(),
                  hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400),
                  filled: true, fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ──── BOTTOM NAVIGATION ────
  Widget _buildBottomNav(bool isDark) {
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == _questions.length - 1;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          if (!isFirst)
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _currentIndex--),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back_ios_rounded, size: 16,
                          color: isDark ? Colors.white54 : Colors.black54),
                        const SizedBox(width: 4),
                        Text('previous'.tr(), style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black54,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (!isFirst) const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: isLast
                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                      : [const Color(0xFF2ECC71), const Color(0xFF8B5CF6)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isLast ? const Color(0xFF10B981) : const Color(0xFF2ECC71)).withValues(alpha: 0.35),
                    blurRadius: 12, offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _isSubmitting
                      ? null
                      : isLast
                          ? () => _submitExam()
                          : () => setState(() => _currentIndex++),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSubmitting)
                        const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      if (!_isSubmitting)
                        Icon(isLast ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(isLast ? 'submit_exam'.tr() : 'next'.tr(), style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15,
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──── SUBMIT ────
  Future<void> _submitExam({bool autoSubmit = false}) async {
    if (_isSubmitting) return;

    if (!autoSubmit) {
      final unanswered = _questions.length - _answers.length;
      if (unanswered > 0) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('submit_exam_q'.tr(), style: const TextStyle(fontWeight: FontWeight.w800)),
            content: Text('unanswered_questions_warning'.tr()),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: Text('review'.tr())),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.pop(c, true),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        if (confirm != true) return;
      }
    }

    setState(() => _isSubmitting = true);
    _timer?.cancel();

    final result = await _cubit.submitExam(
      submissionId: widget.submissionId,
      examId: widget.examId,
      questions: _questions,
      answers: _answers,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result != null) {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => ExamResultScreen(submission: result)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('submit_failed'.tr()),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}
