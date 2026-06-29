import 'package:flutter/material.dart';
import 'package:smart_canvas/features/administrator/dashboard/models/administrator_action_model.dart';
import 'package:line_icons/line_icons.dart';

class AdministratorActionCard extends StatelessWidget {
  final AdministratorActionModel administratorActionModel;
  const AdministratorActionCard({super.key, required this.administratorActionModel});
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getThemeColor(administratorActionModel.title);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Icon(
                administratorActionModel.icon ?? LineIcons.cog, 
                color: color, 
                size: 26
              ),
            ),
            const SizedBox(height: 14),
            Text(
              administratorActionModel.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800, 
                fontSize: 13, 
                color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1E1B15),
                letterSpacing: -0.2,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getThemeColor(String title) {
    final t = title.toLowerCase();
    if (t.contains("user")) return const Color(0xFF2ECC71);
    if (t.contains("building")) return const Color(0xFF10B981);
    if (t.contains("room")) return const Color(0xFFF59E0B);
    if (t.contains("collage") || t.contains("college")) return const Color(0xFF8B5CF6);
    if (t.contains("table") || t.contains("schedule")) return const Color(0xFF1E8449);
    return const Color(0xFF2ECC71);
  }
}
