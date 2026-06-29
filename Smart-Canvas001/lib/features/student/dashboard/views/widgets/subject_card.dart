import 'package:flutter/material.dart';
import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';

class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.subject,
    this.onTap,
  });
  final SubjectModel subject;
  final VoidCallback? onTap;

  Color _getSubjectColor() {
    final int hash = subject.id.hashCode.abs() % 6;
    final List<Color> colors = [
      const Color(0xFF1E8449), // Forest Green / Emerald
      const Color(0xFF1E8449), // Amber / Gold
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFF009688), // Teal
      const Color(0xFFE91E63), // Pink
      const Color(0xFF9C27B0), // Purple
    ];
    return colors[hash];
  }

  IconData _getSubjectIcon() {
    final name = subject.name.toLowerCase();
    if (name.contains('math')) return Icons.calculate_rounded;
    if (name.contains('comput') || name.contains('tech')) return Icons.terminal_rounded;
    if (name.contains('market') || name.contains('busin')) return Icons.trending_up_rounded;
    if (name.contains('design') || name.contains('art')) return Icons.palette_rounded;
    if (name.contains('science')) return Icons.science_rounded;
    return Icons.menu_book_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mainColor = _getSubjectColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1B15) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
              offset: const Offset(0, 10),
              blurRadius: 20,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Radial soft glow decoration in background
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        mainColor.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Double Circle Glowing Icon
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: mainColor.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: mainColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getSubjectIcon(),
                                size: 16,
                                color: mainColor,
                              ),
                            ),
                          ],
                        ),
                        // Course Code tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: mainColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            subject.code?.toUpperCase() ?? "COURSE",
                            style: TextStyle(
                              color: mainColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      subject.name,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                        letterSpacing: -0.3,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subject.academicYearModel?.name ?? "",
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white30 : Colors.grey.shade400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
