import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AttendanceStatsWidget extends StatelessWidget {
  final double attendanceRate;
  final int totalClasses;
  final int attendedClasses;
  final List<Map<String, dynamic>> subjectDetails;
  final VoidCallback? onTap;

  const AttendanceStatsWidget({
    super.key,
    required this.attendanceRate,
    required this.totalClasses,
    required this.attendedClasses,
    this.subjectDetails = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final missedClasses = (totalClasses - attendedClasses).clamp(0, 999);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Adjust padding based on screen width
    final horizontalPadding = screenWidth < 360 ? 12.0 : 24.0;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1B15) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            // Main Stat Card
            Container(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E8449), Color(0xFF27AE60), Color(0xFF2ECC71)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: subjectDetails.isEmpty 
                  ? BorderRadius.circular(32) 
                  : const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildCircularIndicator(screenWidth < 360 ? 60 : 70),
                    SizedBox(width: screenWidth < 360 ? 12 : 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'attendance_rate'.tr(),
                                  style: const TextStyle(
                                    color: Colors.white, 
                                    fontSize: 19, 
                                    fontWeight: FontWeight.w900, 
                                    letterSpacing: -0.6
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 12),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Responsive Wrap for chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildStatChip(Icons.verified_rounded, attendedClasses.toString(), "Attended"),
                              _buildStatChip(Icons.event_busy_rounded, missedClasses.toString(), "Missed"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Subject Breakdown (If any)
            if (subjectDetails.isNotEmpty)
              _buildBreakdownSection(isDark, horizontalPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularIndicator(double size) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: size, height: size,
          child: CircularProgressIndicator(
            value: attendanceRate / 100,
            strokeWidth: 7,
            strokeCap: StrokeCap.round,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        Container(
          width: size - 14,
          height: size - 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          alignment: Alignment.center,
          child: Text(
            '${attendanceRate.toInt()}%',
            style: TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.w900, 
              fontSize: size * 0.23,
              letterSpacing: -0.5
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection(bool isDark, double horizontalPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Subject Analysis", 
                style: TextStyle(
                  fontWeight: FontWeight.w800, 
                  fontSize: 12, 
                  color: isDark ? Colors.white38 : Colors.grey[400],
                  letterSpacing: 0.5
                )),
              const Spacer(),
              Container(height: 1, width: 40, color: Colors.grey.withValues(alpha: 0.1)),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: subjectDetails.map((s) => _buildSubjectMiniCard(s, isDark)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectMiniCard(Map<String, dynamic> subject, bool isDark) {
    final rate = subject['rate'] as double;
    final color = rate >= 75 
        ? const Color(0xFF10B981) 
        : (rate >= 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
    
    return Container(
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      width: 170,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0E0A).withValues(alpha: 0.2) : const Color(0xFFFAF9F5),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.04) 
              : Colors.black.withValues(alpha: 0.03),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subject['name'], 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900, 
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                    letterSpacing: -0.2,
                  )
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: color.withValues(alpha: 0.12),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: rate / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color, 
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 4,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "${rate.toInt()}%", 
                style: TextStyle(
                  fontWeight: FontWeight.w900, 
                  fontSize: 12, 
                  color: color,
                )
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProgressStatsWidget extends StatelessWidget {
  const ProgressStatsWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
