import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:line_icons/line_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_canvas/features/admin/material/view_models/cubit/materials_cubit.dart';
import 'package:smart_canvas/features/admin/material/views/screens/materials_details_screen.dart';

class ProfessorSubjectsListView extends StatelessWidget {
  const ProfessorSubjectsListView({super.key});

  // Subject-specific icons & accent colors for visual variety
  static const _subjectIcons = [
    Icons.science_rounded,
    Icons.computer_rounded,
    Icons.calculate_rounded,
    Icons.auto_stories_rounded,
    Icons.psychology_rounded,
    Icons.language_rounded,
    Icons.architecture_rounded,
    Icons.biotech_rounded,
  ];

  static const _subjectColors = [
    [Color(0xFF2ECC71), Color(0xFF1E8449)],
    [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    [Color(0xFFF59E0B), Color(0xFFD97706)],
    [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    [Color(0xFFEC4899), Color(0xFFBE185D)],
    [Color(0xFF14B8A6), Color(0xFF0D9488)],
    [Color(0xFFF97316), Color(0xFFEA580C)],
    [Color(0xFF6366F1), Color(0xFF4F46E5)],
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: BlocBuilder<MaterialsCubit, MaterialsState>(
        builder: (context, state) {
          final subjects = context.read<MaterialsCubit>().filteredProfessorSubjects;

          if (state is GetMaterialsLoading && subjects.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)));
          }

          if (subjects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LineIcons.book, size: 48, color: Color(0xFF2ECC71)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "No Subjects Yet",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Add your first subject to get started!",
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn();
          }

          return RefreshIndicator(
            onRefresh: () async => context.read<MaterialsCubit>().getProfessorSubjects(),
            color: const Color(0xFF2ECC71),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                final colors = _subjectColors[index % _subjectColors.length];
                final icon = _subjectIcons[index % _subjectIcons.length];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MaterialsDetailsScreen(subject: subject),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1B15) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Subject icon with gradient
                            Container(
                              width: 58, height: 58,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: colors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors[0].withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(icon, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            // Subject info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subject.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF1E1B15),
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: colors[0].withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          subject.code ?? 'N/A',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: colors[0],
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.folder_rounded, size: 12, color: isDark ? Colors.white24 : Colors.black26),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Manage materials",
                                        style: TextStyle(
                                          color: isDark ? Colors.white30 : Colors.black38,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Arrow with circle bg
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: isDark ? Colors.white24 : Colors.black26,
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: (80 * index).ms).slideY(begin: 0.08);
              },
            ),
          );
        },
      ),
    );
  }
}
