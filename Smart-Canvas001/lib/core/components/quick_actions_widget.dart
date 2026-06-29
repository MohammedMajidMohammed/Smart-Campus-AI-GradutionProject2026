import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class QuickActionsWidget extends StatelessWidget {
  final List<QuickAction> actions;
  final String? title;
  
  const QuickActionsWidget({
    super.key,
    required this.actions,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Row(
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
                  title!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            physics: const BouncingScrollPhysics(),
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final action = actions[index];
              return _QuickActionCard(action: action);
            },
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  final QuickAction action;
  const _QuickActionCard({required this.action});
  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.action.color;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.action.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 118,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1B15) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: color.withValues(alpha: isDark ? 0.05 : 0.02),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glowing Icon Container
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: isDark ? 0.08 : 0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: isDark ? 0.16 : 0.1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.action.icon,
                          color: color,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      widget.action.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: isDark ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF0F0E0A),
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            // Top-right premium badge
            if (widget.action.badge != null && widget.action.badge!.isNotEmpty)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E1B15) : Colors.white,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.action.badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });
}

class QuickActions {
  static QuickAction scanQR({required VoidCallback onTap}) => QuickAction(
    icon: Icons.qr_code_scanner_rounded,
    label: 'scan_qr'.tr(),
    color: const Color(0xFF1E8449),
    onTap: onTap,
  );

  static QuickAction viewSchedule({required VoidCallback onTap}) => QuickAction(
    icon: Icons.calendar_today_rounded,
    label: 'schedule'.tr(),
    color: const Color(0xFF10B981),
    onTap: onTap,
  );

  static QuickAction chatbot({required VoidCallback onTap}) => QuickAction(
    icon: Icons.smart_toy_rounded,
    label: 'ai_chat'.tr(),
    color: const Color(0xFF8B5CF6),
    onTap: onTap,
  );

  static QuickAction materials({required VoidCallback onTap}) => QuickAction(
    icon: Icons.auto_stories_rounded,
    label: 'materials'.tr(),
    color: const Color(0xFFF59E0B),
    onTap: onTap,
  );

  static QuickAction announcements({required VoidCallback onTap}) => QuickAction(
    icon: Icons.campaign_rounded,
    label: 'news'.tr(),
    color: const Color(0xFF06B6D4),
    onTap: onTap,
  );

  // --- Admin Quick Actions ---
  static QuickAction manageUsers({required VoidCallback onTap}) => QuickAction(
    icon: Icons.people_rounded,
    label: 'users'.tr(),
    color: const Color(0xFF2ECC71),
    onTap: onTap,
  );

  static QuickAction manageBuildings({required VoidCallback onTap}) => QuickAction(
    icon: Icons.apartment_rounded,
    label: 'buildings'.tr(),
    color: const Color(0xFF1E8449),
    onTap: onTap,
  );

  static QuickAction manageRooms({required VoidCallback onTap}) => QuickAction(
    icon: Icons.meeting_room_rounded,
    label: 'rooms'.tr(),
    color: const Color(0xFF10B981),
    onTap: onTap,
  );

  static QuickAction manageColleges({required VoidCallback onTap}) => QuickAction(
    icon: Icons.school_rounded,
    label: 'colleges'.tr(),
    color: const Color(0xFF8B5CF6),
    onTap: onTap,
  );

  static QuickAction manageTables({required VoidCallback onTap}) => QuickAction(
    icon: Icons.table_chart_rounded,
    label: 'schedules'.tr(),
    color: const Color(0xFFF59E0B),
    onTap: onTap,
  );
}
