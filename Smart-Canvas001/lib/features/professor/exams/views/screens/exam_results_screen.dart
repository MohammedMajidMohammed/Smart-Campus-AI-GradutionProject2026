import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/core/components/glass_box.dart';
import 'package:smart_canvas/features/professor/exams/models/exam_submission_model.dart';
import 'package:smart_canvas/features/professor/exams/view_models/cubit/exams_cubit.dart';
import 'package:smart_canvas/features/professor/exams/views/screens/submission_marking_screen.dart';

class ExamResultsScreen extends StatefulWidget {
  final String examId;
  final String examTitle;

  const ExamResultsScreen({
    super.key,
    required this.examId,
    required this.examTitle,
  });

  @override
  State<ExamResultsScreen> createState() => _ExamResultsScreenState();
}

class _ExamResultsScreenState extends State<ExamResultsScreen>
    with TickerProviderStateMixin {
  final _cubit = ExamsCubit();
  List<ExamSubmissionModel> _results = [];
  bool _isLoading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _loadResults();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    _results = await _cubit.loadExamResults(widget.examId);
    if (mounted) {
      setState(() => _isLoading = false);
      _animController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate stats
    final totalStudents = _results.length;
    final avgScore = totalStudents > 0
        ? _results.map((r) => r.percentage).reduce((a, b) => a + b) / totalStudents
        : 0.0;
    final passed = _results.where((r) => r.isPassed).length;
    final passRate = totalStudents > 0 ? passed / totalStudents : 0.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF0F4F8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── PREMIUM HEADER ───
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFF1E8449),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.examTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      shadows: [Shadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 8)],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.analytics_rounded, size: 13, color: Colors.white.withValues(alpha: 0.9)),
                        const SizedBox(width: 5),
                        Text(
                          'Exam Results Dashboard',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.95),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
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
                    // Geometric pattern
                    Positioned(top: -100, right: -60,
                      child: _DecorativeCircle(size: 300, color: Colors.white.withValues(alpha: 0.06))),
                    Positioned(bottom: -60, left: -40,
                      child: _DecorativeCircle(size: 220, color: Colors.white.withValues(alpha: 0.04))),
                    Positioned(top: 40, left: 30,
                      child: _DecorativeCircle(size: 100, color: Colors.white.withValues(alpha: 0.03))),
                    Positioned(top: 80, right: 60,
                      child: _DecorativeCircle(size: 60, color: Colors.white.withValues(alpha: 0.05))),
                    // Diamond shape
                    Positioned(
                      top: 100, left: MediaQuery.of(context).size.width * 0.4,
                      child: Transform.rotate(
                        angle: math.pi / 4,
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ),
                    ),
                    BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                      child: Container(color: Colors.transparent),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── STATS WITH CIRCULAR PROGRESS ───
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
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
                      // Circular progress for pass rate
                      _buildCircularStat(
                        value: passRate,
                        label: 'Pass Rate',
                        valueText: '${(passRate * 100).toStringAsFixed(0)}%',
                        color: const Color(0xFF10B981),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 24),
                      // Other stats
                      Expanded(
                        child: Column(
                          children: [
                            _miniStatRow(
                              icon: LineIcons.users,
                              label: 'Total Students',
                              value: totalStudents.toString(),
                              color: const Color(0xFF2ECC71),
                              isDark: isDark,
                            ),
                            Divider(color: isDark ? Colors.white12 : Colors.grey.shade100, height: 20),
                            _miniStatRow(
                              icon: Icons.trending_up_rounded,
                              label: 'Average Score',
                              value: '${avgScore.toStringAsFixed(1)}%',
                              color: const Color(0xFFF59E0B),
                              isDark: isDark,
                            ),
                            Divider(color: isDark ? Colors.white12 : Colors.grey.shade100, height: 20),
                            _miniStatRow(
                              icon: LineIcons.checkCircle,
                              label: 'Passed / Total',
                              value: '$passed / $totalStudents',
                              color: const Color(0xFF10B981),
                              isDark: isDark,
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

          // ─── GRADE DISTRIBUTION BAR ───
          if (!_isLoading && _results.isNotEmpty)
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildGradeDistribution(isDark),
                ),
              ),
            ),

          // ─── LEADERBOARD PODIUM ───
          if (!_isLoading && _results.length >= 2)
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildPodium(isDark),
                ),
              ),
            ),

          // ─── SECTION HEADER ───
          if (!_isLoading && _results.isNotEmpty)
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
                      'Student Rankings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFF2ECC71).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_alt_rounded, size: 14, color: isDark ? Colors.white54 : const Color(0xFF2ECC71)),
                          const SizedBox(width: 5),
                          Text(
                            '${_results.length}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white54 : const Color(0xFF2ECC71),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ─── RESULTS LIST ───
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71))),
            )
          else if (_results.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(
                'No Submissions Yet',
                'Student results will appear here once they complete the exam.',
                LineIcons.users,
                isDark,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final result = _results[index];
                    return FadeTransition(
                      opacity: _fadeAnim,
                      child: _ResultCard(
                        result: result,
                        rank: index + 1,
                        isDark: isDark,
                        onRefresh: _loadResults,
                        totalStudents: totalStudents,
                      ),
                    );
                  },
                  childCount: _results.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ─── CIRCULAR STAT ───
  Widget _buildCircularStat({
    required double value,
    required String label,
    required String valueText,
    required Color color,
    required bool isDark,
  }) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 100, height: 100,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 8,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                valueText,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── MINI STAT ROW ───
  Widget _miniStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  // ─── GRADE DISTRIBUTION ───
  Widget _buildGradeDistribution(bool isDark) {
    // Count grades
    int aCount = 0, bCount = 0, cCount = 0, dCount = 0, fCount = 0;
    for (final r in _results) {
      final p = r.percentage;
      if (p >= 90) {
        aCount++;
      } else if (p >= 80) bCount++;
      else if (p >= 70) cCount++;
      else if (p >= 60) dCount++;
      else fCount++;
    }
    final total = _results.length;
    final grades = [
      _GradeData('A', aCount, total, const Color(0xFF10B981)),
      _GradeData('B', bCount, total, const Color(0xFF3B82F6)),
      _GradeData('C', cCount, total, const Color(0xFFF59E0B)),
      _GradeData('D', dCount, total, const Color(0xFFF97316)),
      _GradeData('F', fCount, total, const Color(0xFFEF4444)),
    ];

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF2ECC71), size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Grade Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...grades.map((g) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    g.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: g.color,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: g.fraction,
                      minHeight: 10,
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation(g.color),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${g.count}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ─── PODIUM ───
  Widget _buildPodium(bool isDark) {
    final colors = [const Color(0xFFF59E0B), const Color(0xFF94A3B8), const Color(0xFFB45309)];
    final medals = ['🥇', '🥈', '🥉'];
    final heights = [100.0, 78.0, 60.0];
    final podiumOrder = _results.length >= 3
        ? [_results[1], _results[0], _results[2]]
        : [null, _results[0], _results.length > 1 ? _results[1] : null];
    final podiumRanks = [2, 1, 3];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 16),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Top Performers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) {
              final student = podiumOrder[i];
              final rank = podiumRanks[i];
              final color = colors[rank - 1];
              final isFirst = rank == 1;
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (student != null) ...[
                      // Avatar circle
                      Container(
                        width: isFirst ? 52 : 42,
                        height: isFirst ? 52 : 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            (student.studentName ?? 'S')[0].toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: isFirst ? 22 : 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        student.studentName?.split(' ').first ?? 'Student',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${student.percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Podium bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      height: student != null ? heights[rank - 1] : 0,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.5)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        boxShadow: [
                          BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, -2)),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(medals[rank - 1], style: TextStyle(fontSize: isFirst ? 24 : 18)),
                            Text(
                              '#$rank',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: isFirst ? 18 : 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          // Podium base
          Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── GRADE DATA ───
class _GradeData {
  final String label;
  final int count;
  final double fraction;
  final Color color;

  _GradeData(this.label, this.count, int total, this.color)
      : fraction = total > 0 ? count / total : 0.0;
}

// ─── RESULT CARD ───
class _ResultCard extends StatelessWidget {
  final ExamSubmissionModel result;
  final int rank;
  final bool isDark;
  final VoidCallback onRefresh;
  final int totalStudents;

  const _ResultCard({
    required this.result,
    required this.rank,
    required this.isDark,
    required this.onRefresh,
    required this.totalStudents,
  });

  @override
  Widget build(BuildContext context) {
    final gradeColor = result.isPassed ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final isTopThree = rank <= 3;
    final rankColor = rank == 1
        ? const Color(0xFFF59E0B)
        : rank == 2
            ? const Color(0xFF94A3B8)
            : rank == 3
                ? const Color(0xFFB45309)
                : const Color(0xFF2ECC71);

    // Generate avatar color from name
    final avatarColor = Color(((result.studentName ?? 'S').hashCode & 0xFFFFFF) | 0xFF000000)
        .withValues(alpha: 1.0);
    final initial = (result.studentName ?? 'S')[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTopThree && !isDark
              ? rankColor.withValues(alpha: 0.25)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
          width: isTopThree ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () async {
            final updated = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubmissionMarkingScreen(
                  submissionId: result.id,
                  studentName: result.studentName ?? 'Student',
                ),
              ),
            );
            if (updated == true) {
              onRefresh();
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Rank + Avatar
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                HSLColor.fromColor(avatarColor).withLightness(0.45).toColor(),
                                HSLColor.fromColor(avatarColor).withLightness(0.6).toColor(),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        // Rank badge
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isTopThree ? rankColor : (isDark ? const Color(0xFF2A2720) : Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? const Color(0xFF1E1B15) : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              '#$rank',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                color: isTopThree ? Colors.white : (isDark ? Colors.white54 : Colors.black45),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    // Student info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.studentName ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${result.score.toStringAsFixed(1)} / ${result.totalPoints} pts',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Grade badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: gradeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: gradeColor.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            result.gradeLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: gradeColor,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${result.percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Score progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: result.percentage / 100,
                    minHeight: 6,
                    backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(gradeColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildEmptyState(String title, String subtitle, IconData icon, bool isDark) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2ECC71).withValues(alpha: 0.15),
                    const Color(0xFF2ECC71).withValues(alpha: 0),
                  ],
                ),
              ),
            ),
            GlassBox(
              width: 90, height: 90,
              borderRadius: 24,
              borderOpacity: 0.2,
              blur: 10,
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              child: Icon(icon, size: 42, color: const Color(0xFF2ECC71)),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          title,
          style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15, height: 1.5,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _DecorativeCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
