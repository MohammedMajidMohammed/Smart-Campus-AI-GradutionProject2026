import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smart_canvas/core/app_route/route_names.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_canvas/core/components/quick_actions_widget.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/admin/dashboard/views/widgets/doctor_dash_board_header.dart';
import 'package:smart_canvas/features/admin/dashboard/views/widgets/doctor_action_list_view.dart';
import 'package:smart_canvas/features/admin/dashboard/views/widgets/professor_analytics_widget.dart';
import 'package:smart_canvas/features/admin/dashboard/views/widgets/upcoming_class_widget.dart';

class DoctorDashboardScreenBody extends StatelessWidget {
  const DoctorDashboardScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    // Calculate max width for tablet/desktop centering
    final maxContentWidth = SizeConfig.responsive<double>(
      mobile: double.infinity,
      tablet: 700,
      desktop: 900,
    );

    return RefreshIndicator(
      color: AppColors.kPrimaryColor,
      onRefresh: () async {
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
                // Header - full-bleed within the constrained box
                const DoctorDashboardHeader(),

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
                      // Quick Actions
                      QuickActionsWidget(
                        title: 'quick_actions'.tr(),
                        actions: [
                          QuickAction(
                            label: "subjects".tr(),
                            icon: Icons.menu_book_rounded,
                            color: const Color(0xFF2ECC71), // Indigo
                            onTap: () => context.pushScreen(RouteNames.subjectsScreen),
                          ),
                          QuickAction(
                            label: "materials".tr(),
                            icon: FontAwesomeIcons.bookOpen,
                            color: const Color(0xFFF59E0B), // Amber
                            onTap: () => context.pushScreen(RouteNames.materialsScreen),
                          ),
                          QuickAction(
                            label: "classroom".tr(),
                            icon: Icons.cast_for_education_rounded,
                            color: const Color(0xFF8B5CF6), // Violet
                            onTap: () => context.pushScreen(RouteNames.digitalClassroomScreen),
                          ),
                          QuickActions.announcements(
                            onTap: () => context.pushScreen(RouteNames.enhancedNotificationsScreen),
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.h(2.5)),

                      // Next Class Widget
                      const UpcomingClassWidget(),
                      SizedBox(height: SizeConfig.h(2.5)),

                      // Analytics Dashboard
                      const ProfessorAnalyticsWidget(),
                      SizedBox(height: SizeConfig.h(2.5)),

                      // Tools & Actions Section Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppColors.kPrimaryColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "tools_actions".tr(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F0E0A),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: SizeConfig.h(1)),
                      const DoctorActionListView(),
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
}
