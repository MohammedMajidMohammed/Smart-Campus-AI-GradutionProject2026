import 'package:flutter/material.dart';
import 'package:smart_canvas/core/app_route/route_names.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_canvas/core/components/quick_actions_widget.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/administrator/dashboard/views/widgets/administrator_action_grid_view.dart';
import 'package:smart_canvas/features/administrator/dashboard/views/widgets/administrator_dash_board_header.dart';
import 'package:smart_canvas/features/administrator/dashboard/views/widgets/global_stats_widget.dart';
import 'package:smart_canvas/features/administrator/dashboard/views/widgets/system_health_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdministratorDashboardScreenBody extends StatefulWidget {
  const AdministratorDashboardScreenBody({super.key});

  @override
  State<AdministratorDashboardScreenBody> createState() => _AdministratorDashboardScreenBodyState();
}

class _AdministratorDashboardScreenBodyState extends State<AdministratorDashboardScreenBody> {
  final GlobalKey<GlobalStatsWidgetState> _globalStatsKey = GlobalKey<GlobalStatsWidgetState>();
  final GlobalKey<SystemHealthWidgetState> _systemHealthKey = GlobalKey<SystemHealthWidgetState>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final maxContentWidth = SizeConfig.responsive<double>(
      mobile: double.infinity,
      tablet: 750,
      desktop: 950,
    );

    return Container(
      color: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFFAF9F5),
      child: RefreshIndicator(
        color: const Color(0xFF1E8449),
        onRefresh: () async {
          await Future.wait([
            _globalStatsKey.currentState?.fetchStats() ?? Future.value(),
            Future.delayed(const Duration(milliseconds: 800)),
          ]);
          _systemHealthKey.currentState?.fetchStats();
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const AdministratorDashboardHeader(),
              
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader("OPERATIONAL CONTROL", isDark, "01"),
                        const SizedBox(height: 20),
                        QuickActionsWidget(
                          title: 'quick_actions'.tr(),
                          actions: [
                            QuickActions.manageUsers(
                              onTap: () => context.pushScreen(RouteNames.usersScreen),
                            ),
                            QuickActions.manageBuildings(
                              onTap: () => context.pushScreen(RouteNames.buildingsScreen),
                            ),
                            QuickActions.manageRooms(
                              onTap: () => context.pushScreen(RouteNames.roomsScreen),
                            ),
                            QuickActions.manageColleges(
                              onTap: () => context.pushScreen(RouteNames.collegesScreen),
                            ),
                            QuickActions.manageTables(
                              onTap: () => context.pushScreen(RouteNames.tablesScreen),
                            ),
                            QuickActions.announcements(
                              onTap: () => context.pushScreen(RouteNames.enhancedNotificationsScreen),
                            ),
                          ],
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                        
                        const SizedBox(height: 36),
                        _buildSectionHeader("SYSTEM ANALYTICS", isDark, "02"),
                        const SizedBox(height: 24),
                        GlobalStatsWidget(key: _globalStatsKey)
                            .animate()
                            .fadeIn(delay: 450.ms)
                            .slideY(begin: 0.1),
                            
                        const SizedBox(height: 24),
                        SystemHealthWidget(key: _systemHealthKey)
                            .animate()
                            .fadeIn(delay: 600.ms)
                            .slideY(begin: 0.1),
                            
                        const SizedBox(height: 36),
                        _buildSectionHeader("INFRASTRUCTURE", isDark, "03"),
                        const SizedBox(height: 20),
                        const AdministratorActionGridView()
                            .animate()
                            .fadeIn(delay: 750.ms)
                            .slideY(begin: 0.1),
                            
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark, String number) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E8449).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF1E8449).withValues(alpha: 0.3), width: 1),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Color(0xFF1E8449),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isDark ? Colors.white10 : Colors.grey.shade200,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
