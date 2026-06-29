import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_canvas/core/app_route/route_names.dart';
import 'package:smart_canvas/core/components/quick_actions_widget.dart';
import 'package:smart_canvas/core/components/analytics_widgets.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/student/dashboard/views/widgets/doctor_action_grid_view.dart';
import 'package:smart_canvas/features/student/dashboard/views/widgets/exam_countdown_widget.dart';
import 'package:smart_canvas/features/student/dashboard/views/widgets/schedule_timeline_widget.dart';
import 'package:smart_canvas/features/student/dashboard/views/widgets/student_dash_board_header.dart';
import 'package:smart_canvas/features/student/dashboard/views/widgets/upcoming_deadlines_widget.dart';
import 'package:smart_canvas/features/student/dashboard/views/widgets/live_polls_widget.dart';
import 'package:smart_canvas/features/student/dashboard/view_models/cubit/upcoming_deadlines/upcoming_deadlines_cubit.dart';
import 'package:smart_canvas/features/student/dashboard/view_models/cubit/upcoming_deadlines/upcoming_deadlines_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/features/student/dashboard/view_models/cubit/attendance_cubit/attendance_cubit.dart';
import 'package:smart_canvas/core/components/shimmer_loading.dart';
import 'package:smart_canvas/features/student/dashboard/view_models/college_data_cubit.dart';
import 'package:smart_canvas/features/student/schedule/view_models/cubit/student_schedule_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentDashboardScreenBody extends StatelessWidget {
  const StudentDashboardScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate max width for tablet/desktop centering
    final maxContentWidth = SizeConfig.responsive<double>(
      mobile: double.infinity,
      tablet: 700,
      desktop: 900,
    );

    return RefreshIndicator(
      color: AppColors.kPrimaryColor,
      onRefresh: () async {
        context.read<AttendanceCubit>().fetchAttendanceData();
        context.read<CollegeDataCubit>().getStudentSubjects();
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header (floating card layout with its own margins)
                const StudentDashboardHeader(),

                // Main body content with horizontal and vertical padding
                Padding(
                  padding: EdgeInsets.only(
                    left: SizeConfig.responsive<double>(
                      mobile: SizeConfig.w(4),
                      tablet: SizeConfig.w(3),
                      desktop: SizeConfig.w(2),
                    ),
                    right: SizeConfig.responsive<double>(
                      mobile: SizeConfig.w(4),
                      tablet: SizeConfig.w(3),
                      desktop: SizeConfig.w(2),
                    ),
                    top: SizeConfig.h(1.5),
                    bottom: SizeConfig.h(3),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Quick Actions
                      QuickActionsWidget(
                        title: 'quick_actions'.tr(),
                        actions: [
                          QuickActions.scanQR(
                            onTap: () async {
                              await Navigator.pushNamed(context, RouteNames.qrScannerScreen);
                              if (context.mounted) {
                                context.read<AttendanceCubit>().fetchAttendanceData();
                              }
                            },
                          ),
                          QuickActions.viewSchedule(
                            onTap: () => context.pushScreen(RouteNames.studySchedulesScreen),
                          ),
                          QuickActions.chatbot(
                            onTap: () => context.pushScreen(RouteNames.chatbotsScreen),
                          ),
                          QuickActions.materials(
                            onTap: () => context.pushScreen(RouteNames.studentMaterialsScreen),
                          ),
                          QuickAction(
                            label: "exams".tr(),
                            icon: Icons.quiz_rounded,
                            color: const Color(0xFF10B981),
                            onTap: () => context.pushScreen(RouteNames.studentExamsScreen),
                          ),
                          QuickActions.announcements(
                            onTap: () => context.pushScreen(RouteNames.enhancedNotificationsScreen),
                          ),
                          QuickAction(
                            label: "virtual_classes".tr(),
                            icon: Icons.video_camera_front_rounded,
                            color: const Color(0xFFF59E0B),
                            onTap: () => context.pushScreen(RouteNames.studentOnlineSessionsScreen),
                          ),
                          QuickAction(
                            label: "subject_chat_btn".tr(),
                            icon: Icons.chat_bubble_rounded,
                            color: const Color(0xFF2ECC71),
                            onTap: () => context.pushScreen(RouteNames.studentSubjectChatListScreen),
                          ),
                          QuickAction(
                            label: "Student Portal",
                            icon: Icons.account_balance_rounded,
                            color: const Color(0xFF1E8449),
                            onTap: () async {
                              final url = Uri.parse('https://mnustdch.menofia.education/static/index.html');
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            },
                          ),
                          QuickAction(
                            label: "LMS Platform",
                            icon: Icons.school_rounded,
                            color: const Color(0xFF8B5CF6),
                            onTap: () async {
                              final url = Uri.parse('https://mnulms.menofia.education/login/index.php');
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.h(2.5)),

                      // 2.5 Live Polls
                      const LivePollsWidget(),
                      SizedBox(height: SizeConfig.h(2.5)),

                      // 3. Attendance Stats
                      BlocBuilder<AttendanceCubit, AttendanceState>(
                        builder: (context, state) {
                          if (state is AttendanceLoaded) {
                            return AttendanceStatsWidget(
                              attendanceRate: state.overallRate,
                              totalClasses: state.totalClasses,
                              attendedClasses: state.attendedClasses,
                              subjectDetails: state.subjectsAttendance,
                              onTap: () async {
                                await Navigator.pushNamed(context, RouteNames.studentAttendanceHistoryScreen);
                                if (context.mounted) {
                                  context.read<AttendanceCubit>().fetchAttendanceData();
                                }
                              },
                            );
                          } else if (state is AttendanceError) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${'unable_load_attendance'.tr()}: ${state.message}',
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            );
                          }
                          return ShimmerCard(height: SizeConfig.height * 0.15, borderRadius: 24);
                        },
                      ),
                      SizedBox(height: SizeConfig.h(2.5)),

                      // 4. Dynamic Sections (Timers & Deadlines)
                      BlocProvider(
                        create: (context) => UpcomingDeadlinesCubit()..subscribeToDeadlines(),
                        child: BlocBuilder<UpcomingDeadlinesCubit, UpcomingDeadlinesState>(
                          builder: (context, state) {
                            return Column(
                              children: [
                                // 4a. Next Lecture Timer
                                BlocProvider(
                                  create: (context) => StudentScheduleCubit(),
                                  child: BlocBuilder<StudentScheduleCubit, StudentScheduleState>(
                                    builder: (context, scheduleState) {
                                      if (scheduleState is StudentScheduleLoading) return const SizedBox();
                                      final cubit = BlocProvider.of<StudentScheduleCubit>(context);
                                      final nextClass = cubit.getNextUpcomingClass();
                                      if (nextClass == null) return const SizedBox();

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 20),
                                        child: LectureCountdownWidget(
                                          title: nextClass['subject'].subjectName ?? "Next Lecture",
                                          startTime: nextClass['time'] as DateTime,
                                          endTime: (nextClass['time'] as DateTime).add(const Duration(hours: 2)),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // 4b. Nearest Exam Timer
                                if (state is UpcomingDeadlinesLoaded)
                                  _buildNearestExamTimer(state.deadlines),

                                // 4c. Timeline
                                const ScheduleTimelineWidget(),
                                SizedBox(height: SizeConfig.h(2.5)),

                                // 4d. Upcoming Deadlines List
                                if (state is UpcomingDeadlinesLoaded)
                                  UpcomingDeadlinesWidget(deadlines: state.deadlines),
                                if (state is UpcomingDeadlinesLoading)
                                  const ShimmerCard(height: 200, borderRadius: 24),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(height: SizeConfig.h(2.5)),

                      // 5. My Subjects Section Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E8449),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "my_subjects".tr(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () => context.pushScreen(RouteNames.studentSubjectsScreen),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                backgroundColor: const Color(0xFF1E8449).withValues(alpha: 0.08),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(
                                'view_all'.tr(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E8449),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const StudentSubjectsGridView(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNearestExamTimer(List<DeadlineItem> deadlines) {
    try {
      final exams = deadlines.where((d) => d.type == 'exam').toList();
      if (exams.isEmpty) return const SizedBox();
      
      final nearestExam = exams.first;
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: LectureCountdownWidget(
          title: "Upcoming Exam: ${nearestExam.title}",
          startTime: nearestExam.dueDate,
          endTime: nearestExam.endDate,
          isExam: true,
        ),
      );
    } catch (e) {
      return const SizedBox();
    }
  }
}
