import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/app_route/route_names.dart';
import 'package:smart_canvas/core/components/quick_actions_widget.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/professor/schedule/view_models/cubit/professor_schedule_cubit.dart';
import 'package:smart_canvas/features/professor/dashboard/views/widgets/professor_dashboard_header.dart';

class ProfessorDashboardScreenBody extends StatelessWidget {
  const ProfessorDashboardScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final maxContentWidth = SizeConfig.responsive<double>(
      mobile: double.infinity,
      tablet: 700,
      desktop: 900,
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Immersive Header
              const ProfessorDashboardHeader(),
              
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.responsive<double>(
                    mobile: SizeConfig.w(4),
                    tablet: SizeConfig.w(3),
                    desktop: SizeConfig.w(2),
                  ),
                  vertical: SizeConfig.h(2.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Quick Actions Section
                    QuickActionsWidget(
                      title: 'quick_actions'.tr(),
                      actions: [
                        QuickAction(
                          label: "my_schedule".tr(),
                          icon: Icons.calendar_month_rounded, 
                          color: const Color(0xFF10B981),
                          onTap: () => context.pushScreen(RouteNames.professorSchedulesScreen),
                        ),
                        QuickAction(
                          label: "exams".tr(),
                          icon: Icons.quiz_rounded,
                          color: const Color(0xFF8B5CF6),
                          onTap: () => context.pushScreen(RouteNames.examsScreen),
                        ),
                        QuickAction(
                          label: "upload_books".tr(),
                          icon: Icons.auto_stories_rounded,
                          color: Colors.orange,
                          onTap: () => context.pushScreen(RouteNames.materialsScreen),
                        ),
                        QuickAction(
                          label: "virtual_classes".tr(),
                          icon: Icons.video_camera_front_rounded,
                          color: const Color(0xFFF59E0B),
                          onTap: () => context.pushScreen(RouteNames.professorOnlineSessionsScreen),
                        ),
                        QuickAction(
                          label: "assignments".tr(),
                          icon: Icons.assignment_rounded,
                          color: const Color(0xFF1E8449),
                          onTap: () => context.pushScreen(RouteNames.doctorAssignmentsScreen),
                        ),
                        QuickAction(
                          label: "subject_chat_btn".tr(),
                          icon: Icons.chat_bubble_rounded,
                          color: const Color(0xFF2ECC71),
                          onTap: () => context.pushScreen(RouteNames.professorSubjectChatListScreen),
                        ),
                        QuickAction(
                          label: "attendance".tr(),
                          icon: Icons.qr_code_scanner_rounded,
                          color: const Color(0xFFEF4444),
                          onTap: () => context.pushScreen(RouteNames.qrAttendanceScreen),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.h(3.5)),

                    // 3. Today's Classes Section Header
                    _buildSectionHeader(context, "todays_classes".tr(), isDark, () {
                      context.pushScreen(RouteNames.professorSchedulesScreen);
                    }),
                    SizedBox(height: SizeConfig.h(1.5)),
                    
                    // 4. Today's Classes List
                    BlocBuilder<ProfessorScheduleCubit, SchedulesState>(
                      builder: (context, state) {
                        if (state is GetSchedulesLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        final cubit = context.read<ProfessorScheduleCubit>();
                        final today = _getTodayAbbreviation();
                        final todaySchedules = cubit.subjectScheduleModels.where((s) => s.formattedDay == today).toList();

                        if (todaySchedules.isEmpty) {
                          return _buildEmptyState(context, isDark);
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: todaySchedules.length > 5 ? 5 : todaySchedules.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final schedule = todaySchedules[index];
                            return _buildClassCard(context, schedule, isDark);
                          },
                        );
                      },
                    ),
                    SizedBox(height: SizeConfig.h(4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark, VoidCallback onSeeAll) {
    return Row(
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
              title,
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
          onPressed: onSeeAll,
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
    );
  }

  Widget _buildClassCard(BuildContext context, dynamic schedule, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2ECC71), Color(0xFF1E8449)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: const Color(0xFF2ECC71).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Text(
              schedule.timeSlot.split(' ')[0],
              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.subjectName,
                  style: TextStyle(
                    fontWeight: FontWeight.w900, 
                    fontSize: 17,
                    color: isDark ? Colors.white : const Color(0xFF1E1B15),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: AppColors.kPrimaryColor),
                    const SizedBox(width: 6),
                    Text(
                      schedule.room?.name ?? "No Room",
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15).withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFF1E8449).withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.03),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Layered Glowing Calendar Orb
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E8449).withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E8449).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E8449).withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  size: 28,
                  color: Color(0xFF1E8449),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "no_classes_today".tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F0E0A),
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.locale.languageCode == 'ar' ? 'يمكنك الاستمتاع بيومك المريح اليوم!' : 'Enjoy your relaxing day today!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey.shade500,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getTodayAbbreviation() {
    final now = DateTime.now();
    switch (now.weekday) {
      case DateTime.saturday: return 'Sat';
      case DateTime.sunday: return 'Sun';
      case DateTime.monday: return 'Mon';
      case DateTime.tuesday: return 'Tue';
      case DateTime.wednesday: return 'Wed';
      case DateTime.thursday: return 'Thu';
      case DateTime.friday: return 'Fri';
      default: return 'Sat';
    }
  }
}
