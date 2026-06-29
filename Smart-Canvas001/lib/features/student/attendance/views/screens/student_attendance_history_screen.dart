import 'package:flutter/material.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/student/dashboard/repositories/attendance_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

class StudentAttendanceHistoryScreen extends StatefulWidget {
  const StudentAttendanceHistoryScreen({super.key});

  @override
  State<StudentAttendanceHistoryScreen> createState() => _StudentAttendanceHistoryScreenState();
}

class _StudentAttendanceHistoryScreenState extends State<StudentAttendanceHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final user = getIt<CacheHelper>().getUserModel();
    if (user != null) {
      final repo = AttendanceRepository(getIt<SupabaseClient>());
      _historyFuture = repo.getStudentAttendanceWithSubjects(user.id);
    } else {
      _historyFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFFAF9F5),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Professional University Brand Green-to-Gold Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.kPrimaryColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 20),
              title: Text(
                'my_attendance'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: -0.5,
                  shadows: [Shadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(0, 4), blurRadius: 12)],
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.kPrimaryColor, Color(0xFF9E7B1A)], // University Green to Gold Logo Palette
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      top: -80, right: -80,
                      child: _HeaderDecorationCircle(size: 260, opacity: 0.1),
                    ),
                    const Positioned(
                      bottom: -40, left: -40,
                      child: _HeaderDecorationCircle(size: 180, opacity: 0.05),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                )
                              ],
                            ),
                            child: const Icon(Icons.event_available_rounded, size: 36, color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Section Title Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
              child: Row(
                children: [
                  Text(
                    "your_progress".tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.w900, 
                      fontSize: 18, 
                      color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.info_outline_rounded, size: 16, color: isDark ? Colors.white30 : Colors.grey.shade400),
                ],
              ),
            ),
          ),

          FutureBuilder<List<Map<String, dynamic>>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.kPrimaryColor)));
              }

              final subjects = snapshot.data ?? [];
              if (subjects.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState());
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final subject = subjects[index];
                      // Choose color from brand logo palette (alternating Green and Gold)
                      final cardColor = index % 2 == 0 ? AppColors.kPrimaryColor : AppColors.kSecondaryColor;

                      return _PremiumAttendanceCard(
                        subjectName: subject['subject_name'],
                        totalAttended: subject['total_attended'],
                        weeks: List<int>.from(subject['weeks']),
                        isDark: isDark,
                        color: cardColor,
                      );
                    },
                    childCount: subjects.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text("No records found", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _PremiumAttendanceCard extends StatelessWidget {
  final String subjectName;
  final int totalAttended;
  final List<int> weeks;
  final bool isDark;
  final Color color;

  const _PremiumAttendanceCard({
    required this.subjectName,
    required this.totalAttended,
    required this.weeks,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (totalAttended / 16 * 100).clamp(0.0, 100.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Professional Card Header with brand logo colors
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1B15) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.book_rounded, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectName, 
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F0E0A), 
                          fontWeight: FontWeight.w900, 
                          fontSize: 17, 
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$totalAttended Sessions Attended", 
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.grey.shade600, 
                          fontSize: 13, 
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 50, height: 50,
                      child: CircularProgressIndicator(
                        value: percentage / 100,
                        strokeWidth: 5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    Text(
                      "${percentage.toInt()}%",
                      style: TextStyle(
                        color: color, 
                        fontWeight: FontWeight.w900, 
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Matrix Grid
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Attendance Matrix", 
                      style: TextStyle(
                        fontWeight: FontWeight.w800, 
                        fontSize: 13, 
                        color: isDark ? Colors.white30 : Colors.grey.shade400,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Icon(Icons.grid_view_rounded, size: 14, color: isDark ? Colors.white30 : Colors.grey.shade400),
                  ],
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: 16,
                  itemBuilder: (context, index) {
                    final weekNum = index + 1;
                    final isAttended = weeks.contains(weekNum);
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        gradient: isAttended ? LinearGradient(
                          colors: [color, color.withValues(alpha: 0.85)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ) : null,
                        color: isAttended ? null : (isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAF9F5)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isAttended ? Colors.transparent : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                          width: 1.5,
                        ),
                        boxShadow: isAttended ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ] : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            "$weekNum",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: isAttended ? Colors.white : (isDark ? Colors.white24 : Colors.grey.shade300),
                            ),
                          ),
                          if (isAttended)
                            const Positioned(
                              top: 4,
                              right: 4,
                              child: Icon(
                                Icons.check_circle_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Summary progress bar
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1), 
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withValues(alpha: 0.6), color],
                        ), 
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderDecorationCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _HeaderDecorationCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)),
    );
  }
}
