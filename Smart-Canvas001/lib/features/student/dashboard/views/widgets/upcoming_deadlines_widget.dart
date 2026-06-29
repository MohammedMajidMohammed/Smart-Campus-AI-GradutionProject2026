import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_canvas/core/components/dashboard_container.dart';
import 'package:smart_canvas/features/student/dashboard/view_models/cubit/upcoming_deadlines/upcoming_deadlines_state.dart';
import 'package:smart_canvas/core/app_route/route_names.dart';

class UpcomingDeadlinesWidget extends StatelessWidget {
  final List<DeadlineItem> deadlines;

  const UpcomingDeadlinesWidget({
    super.key,
    required this.deadlines,
  });

  @override
  Widget build(BuildContext context) {
    if (deadlines.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'upcoming_deadlines'.tr(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        ...deadlines.take(5).map((deadline) => _buildDeadlineItem(context, deadline)),
      ],
    );
  }

  Widget _buildDeadlineItem(BuildContext context, DeadlineItem deadline) {
    final diff = deadline.dueDate.difference(DateTime.now());
    final daysLeft = diff.inDays;
    final hoursLeft = diff.inHours;
    
    final isUrgent = hoursLeft < 24;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String timeText;
    if (daysLeft == 0) {
      if (hoursLeft <= 0) {
        timeText = 'Starting now';
      } else {
        timeText = 'Today (${hoursLeft}h left)';
      }
    } else if (daysLeft == 1) {
      timeText = 'tomorrow'.tr();
    } else {
      timeText = 'days_remaining'.tr(args: [daysLeft.toString()]);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          switch (deadline.type) {
            case 'exam':
              Navigator.pushNamed(context, RouteNames.studentExamsScreen);
              break;
            case 'assignment':
              Navigator.pushNamed(context, RouteNames.studentAssignmentsScreen);
              break;
            case 'session':
              Navigator.pushNamed(context, RouteNames.studentOnlineSessionsScreen);
              break;
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: DashboardContainer(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: deadline.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  deadline.icon,
                  color: deadline.color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deadline.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deadline.subject,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isUrgent 
                      ? Colors.red.withValues(alpha: 0.1) 
                      : deadline.color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUrgent ? Colors.red.withValues(alpha: 0.2) : Colors.transparent,
                  ),
                ),
                child: Text(
                  timeText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isUrgent ? Colors.red : deadline.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
