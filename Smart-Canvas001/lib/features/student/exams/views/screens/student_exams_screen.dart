import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/professor/exams/models/exam_model.dart';
import 'package:smart_canvas/features/student/exams/view_models/cubit/student_exam_cubit.dart';
import 'package:smart_canvas/features/student/exams/views/screens/student_result_review_screen.dart';
import 'package:smart_canvas/features/student/exams/views/screens/take_exam_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class StudentExamsScreen extends StatelessWidget {
  const StudentExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StudentExamCubit()..loadAvailableExams()..subscribeToRealTimeChanges(),
      child: const _StudentExamsView(),
    );
  }
}

class _StudentExamsView extends StatefulWidget {
  const _StudentExamsView();

  @override
  State<_StudentExamsView> createState() => _StudentExamsViewState();
}

class _StudentExamsViewState extends State<_StudentExamsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFFAF9F5),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            elevation: 0,
            stretch: true,
            backgroundColor: isDark ? const Color(0xFF1E1B15) : AppColors.kPrimaryColor,
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
              stretchModes: const [StretchMode.blurBackground, StretchMode.zoomBackground],
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E1B15), const Color(0xFF0F0E0A)]
                        : [const Color(0xFF1E8449), const Color(0xFF1E8449)],
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
                      bottom: 60, left: -20,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.03),
                        ),
                      ),
                    ),
                    // Center content
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 48),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.1),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 2),
                              ),
                              child: const Icon(Icons.quiz_rounded, size: 32, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'exams'.tr(),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                shadows: [Shadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8)],
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
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  labelColor: AppColors.kPrimaryColor,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: 'exam_tab'.tr()),
                    Tab(text: 'results_tab'.tr()),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: BlocBuilder<StudentExamCubit, StudentExamState>(
          builder: (context, state) {
            if (state is StudentExamLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.kPrimaryColor));
            }
            if (state is StudentExamsLoaded) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildExamList(state.available, isDark),
                  _buildResultList(state.completed, isDark),
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildExamList(List<ExamModel> exams, bool isDark) {
    if (exams.isEmpty) return _buildEmptyState(true, isDark);

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: exams.length,
      itemBuilder: (context, index) => _ExamCard(exam: exams[index], isDark: isDark),
    );
  }

  Widget _buildResultList(List<Map<String, dynamic>> results, bool isDark) {
    if (results.isEmpty) return _buildEmptyState(false, isDark);

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final exam = results[index]['exam'] as ExamModel;
        final submission = results[index]['submission'] as Map<String, dynamic>;
        return _ResultCard(
          exam: exam,
          submissionId: submission['id']?.toString() ?? '',
          score: (submission['score'] as num?)?.toDouble() ?? 0.0,
          total: (submission['total_points'] as num?)?.toInt() ?? 0,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildEmptyState(bool isAvailable, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.grey.shade100,
            ),
            child: Icon(
              isAvailable ? Icons.quiz_outlined : Icons.history_rounded,
              size: 48,
              color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isAvailable ? "No Exams Available" : "No Results Yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white30 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAvailable
                ? "Check back later for upcoming exams"
                : "Complete exams to see your results here",
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade300,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Exam Card ───────────────────────────────────────────────

class _ExamCard extends StatelessWidget {
  final ExamModel exam;
  final bool isDark;
  const _ExamCard({required this.exam, required this.isDark});

  @override
  Widget build(BuildContext context) {
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
        children: [
          // Top section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E8449), Color(0xFF2ECC71)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E8449).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exam.subjectName ?? "Subject",
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(isOpen: exam.isOpen, isDark: isDark),
              ],
            ),
          ),

          // Bottom section with info tags and button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAFBFC),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                _InfoChip(
                  icon: Icons.timer_outlined,
                  label: "${exam.durationMinutes} min",
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InfoChip(
                    icon: Icons.calendar_month_outlined,
                    label: DateFormat('MMM dd, hh:mm a').format(exam.openAt.toLocal()),
                    isDark: isDark,
                  ),
                ),
                if (exam.isOpen) ...[
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => _handleStart(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E8449), Color(0xFF2ECC71)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E8449).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            "START",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
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

  void _handleStart(BuildContext context) async {
    final cubit = context.read<StudentExamCubit>();
    final submissionId = await cubit.startExam(exam.id);
    if (submissionId != null && context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => TakeExamScreen(
        examId: exam.id, examTitle: exam.title, submissionId: submissionId, durationMinutes: exam.durationMinutes,
      )));
    }
  }
}

// ─── Result Card ─────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final ExamModel exam;
  final String submissionId;
  final double score;
  final int total;
  final bool isDark;

  const _ResultCard({
    required this.exam,
    required this.submissionId,
    required this.score,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (score / total) * 100 : 0.0;
    final isPassed = percentage >= 50;
    final isExcellent = percentage >= 85;
    
    // Color palette based on score
    final Color statusColor;
    final List<Color> gradientColors;
    final String gradeLabel;
    
    if (isExcellent) {
      statusColor = AppColors.kSecondaryColor;
      gradientColors = [const Color(0xFF1E8449), const Color(0xFF9E7B1A)];
      gradeLabel = "EXCELLENT";
    } else if (isPassed) {
      statusColor = const Color(0xFF22C55E);
      gradientColors = [const Color(0xFF1E8449), const Color(0xFF2ECC71)];
      gradeLabel = "PASSED";
    } else {
      statusColor = const Color(0xFFEF4444);
      gradientColors = [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      gradeLabel = "FAILED";
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentResultReviewScreen(
              submissionId: submissionId,
              examTitle: exam.title,
              score: score,
              totalPoints: total,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
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
          children: [
            // Score header section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gradientColors[0].withValues(alpha: isDark ? 0.15 : 0.06),
                    gradientColors[1].withValues(alpha: isDark ? 0.08 : 0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  // Large score ring
                  SizedBox(
                    width: 68, height: 68,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 68, height: 68,
                          child: CircularProgressIndicator(
                            value: total > 0 ? score / total : 0,
                            strokeWidth: 6,
                            color: statusColor,
                            backgroundColor: statusColor.withValues(alpha: 0.12),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${percentage.toInt()}%",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: statusColor,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exam.subjectName ?? "Subject",
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey.shade400,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Grade badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: gradientColors),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: gradientColors[0].withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            gradeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bottom section
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAFBFC),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.score_rounded, size: 14, color: isDark ? Colors.white24 : Colors.grey.shade300),
                  const SizedBox(width: 6),
                  Text(
                    "${score.toStringAsFixed(1)} / $total",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradientColors),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors[0].withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          "Review",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.3,
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
      ),
    );
  }
}

// ─── Helper Widgets ──────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isOpen;
  final bool isDark;
  const _StatusBadge({required this.isOpen, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? const Color(0xFF22C55E) : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            isOpen ? "Open" : "Upcoming",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _InfoChip({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isDark ? Colors.white30 : Colors.grey.shade400),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
