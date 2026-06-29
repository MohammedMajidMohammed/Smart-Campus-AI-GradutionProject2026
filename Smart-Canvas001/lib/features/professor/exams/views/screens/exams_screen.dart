import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/professor/exams/models/exam_model.dart';
import 'package:smart_canvas/features/professor/exams/view_models/cubit/exams_cubit.dart';
import 'package:smart_canvas/features/professor/exams/views/screens/create_exam_screen.dart';
import 'package:smart_canvas/features/professor/exams/views/screens/exam_results_screen.dart';
import 'package:smart_canvas/features/professor/exams/views/screens/exam_questions_screen.dart';

class ExamsScreen extends StatelessWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExamsCubit()..subscribeToRealtimeExams(),
      child: const _ExamsView(),
    );
  }
}

class _ExamsView extends StatelessWidget {
  const _ExamsView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGrad = isDark
        ? [const Color(0xFF1E1B15), const Color(0xFF2A2720)]
        : [AppColors.kPrimaryColor, const Color(0xFF1E8449)];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFF1F5F9),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ──── PREMIUM HEADER ────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            elevation: 0,
            backgroundColor: primaryGrad[0],
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                'My Exams',
                style: TextStyle(
                  fontWeight: FontWeight.w800, 
                  fontSize: 22, 
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: primaryGrad,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -60, right: -40,
                      child: _decorCircle(220, 0.08),
                    ),
                    Positioned(
                      bottom: -30, left: -20,
                      child: _decorCircle(140, 0.06),
                    ),
                    Positioned(
                      top: 30, right: 60,
                      child: _decorCircle(60, 0.12),
                    ),
                    // Stats row in glassmorphic container
                    Positioned(
                      left: 20, right: 20, bottom: 50,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
                            ),
                            child: BlocBuilder<ExamsCubit, ExamsState>(
                              builder: (context, state) {
                                final total = state is ExamsLoaded ? state.exams.length : 0;
                                final active = state is ExamsLoaded ? state.exams.where((e) => e.isOpen).length : 0;
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Expanded(child: _headerStat('Total Exams', '$total', Icons.quiz_rounded)),
                                    Container(width: 1, height: 28, color: Colors.white24),
                                    Expanded(child: _headerStat('Active Exams', '$active', Icons.play_circle_filled_rounded)),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ──── BODY ────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            sliver: BlocBuilder<ExamsCubit, ExamsState>(
              builder: (context, state) {
                if (state is ExamsLoading) {
                  return SliverFillRemaining(
                    child: Center(
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
                          Text('Loading exams...', style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                          )),
                        ],
                      ),
                    ),
                  );
                }

                if (state is ExamsError) {
                  return SliverFillRemaining(
                    child: _emptyOrError(isDark, isError: true, message: state.message),
                  );
                }

                if (state is ExamsLoaded) {
                  if (state.exams.isEmpty) {
                    return SliverFillRemaining(
                      child: _emptyOrError(isDark, isError: false),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _ProfessorExamCard(
                        exam: state.exams[index],
                        isDark: isDark,
                      ),
                      childCount: state.exams.length,
                    ),
                  );
                }

                return const SliverFillRemaining(child: SizedBox());
              },
            ),
          ),
        ],
      ),
      // ──── CREATE BUTTON ────
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Container(
      height: 56, width: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [AppColors.kPrimaryColor, Color(0xFF2ECC71)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimaryColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateExamScreen()),
            );
            if (context.mounted) {
              context.read<ExamsCubit>().loadExams();
            }
          },
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  static Widget _decorCircle(double size, double opacity) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }

  static Widget _headerStat(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800,
              ), overflow: TextOverflow.ellipsis),
              Text(label, style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75), fontSize: 11, fontWeight: FontWeight.w600,
              ), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyOrError(bool isDark, {bool isError = false, String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  (isError ? Colors.red : const Color(0xFF2ECC71)).withValues(alpha: 0.12),
                  (isError ? Colors.red : const Color(0xFF8B5CF6)).withValues(alpha: 0.04),
                ],
              ),
            ),
            child: Icon(
              isError ? LineIcons.exclamationTriangle : LineIcons.clipboardList,
              size: 52,
              color: isError ? Colors.red.shade400 : const Color(0xFF2ECC71),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isError ? 'Something Went Wrong' : 'No Exams Yet',
            style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              isError
                  ? message ?? 'An error occurred'
                  : 'Create your first exam by tapping the + button below',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38, fontSize: 14, height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  PROFESSOR EXAM CARD — Premium design
// ════════════════════════════════════════════════════════════════

class _ProfessorExamCard extends StatelessWidget {
  final ExamModel exam;
  final bool isDark;

  const _ProfessorExamCard({required this.exam, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final statusColor = exam.isOpen
        ? const Color(0xFF10B981)
        : exam.isUpcoming
            ? const Color(0xFFF59E0B)
            : const Color(0xFF94A3B8);

    final statusIcon = exam.isOpen
        ? Icons.play_circle_filled_rounded
        : exam.isUpcoming
            ? Icons.schedule_rounded
            : Icons.check_circle_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Icon + Title/Subject + Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.kPrimaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.assignment_turned_in_rounded, 
                        color: AppColors.kPrimaryColor, 
                        size: 24
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exam.title, 
                            style: TextStyle(
                              fontSize: 17, 
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (exam.subjectName != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.book_outlined, 
                                  size: 13,
                                  color: isDark ? Colors.white38 : Colors.grey.shade500
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    exam.subjectName!, 
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white38 : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusBadge(statusColor, statusIcon),
                  ],
                ),
                const SizedBox(height: 18),

                // Stats Row with micro icons
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded, 
                      size: 14, 
                      color: isDark ? Colors.white38 : Colors.grey.shade500
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${exam.durationMinutes} min', 
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.grey.shade700,
                      )
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.help_outline_rounded, 
                      size: 14, 
                      color: isDark ? Colors.white38 : Colors.grey.shade500
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${exam.questionCount ?? 0} ${exam.questionCount == 1 ? 'question' : 'questions'}', 
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.grey.shade700,
                      )
                    ),
                    if (exam.isOpen || exam.isUpcoming) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.event_note_rounded, 
                        size: 14, 
                        color: isDark ? Colors.white38 : Colors.grey.shade500
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          DateFormat('MMM dd, hh:mm a').format(exam.openAt.toLocal()),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white54 : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Custom Divider
          Container(
            height: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
          ),

          // Card Footer Actions Row (Grey background section)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                // Questions Action
                TextButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ExamQuestionsScreen(examId: exam.id, examTitle: exam.title),
                  )),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.kPrimaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.list_alt_rounded, size: 16),
                  label: const Text(
                    'Questions',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 4),
                // Results Action
                TextButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ExamResultsScreen(examId: exam.id, examTitle: exam.title),
                  )),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF196F3D),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.bar_chart_rounded, size: 16),
                  label: const Text(
                    'Results',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                // Edit Action
                IconButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CreateExamScreen(exam: exam),
                  )),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(
                    Icons.edit_outlined, 
                    size: 18, 
                    color: isDark ? Colors.white54 : Colors.grey.shade600
                  ),
                ),
                const SizedBox(width: 4),
                // Active Switch
                Transform.scale(
                  scale: 0.8,
                  child: Switch.adaptive(
                    value: exam.isActive,
                    activeThumbColor: AppColors.kPrimaryColor,
                    activeTrackColor: AppColors.kPrimaryColor.withValues(alpha: 0.5),
                    onChanged: (val) => context.read<ExamsCubit>().toggleExamActive(exam.id, val),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            exam.statusLabel,
            style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
