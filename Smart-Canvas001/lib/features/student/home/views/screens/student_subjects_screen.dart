import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:line_icons/line_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_canvas/core/app_route/route_names.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/student/dashboard/view_models/college_data_cubit.dart';
import 'package:smart_canvas/features/student/dashboard/views/widgets/subject_card.dart';
import 'package:easy_localization/easy_localization.dart';

class StudentSubjectsScreen extends StatelessWidget {
  final bool isMaterialsView; // If true, title is 'Study Materials'
  const StudentSubjectsScreen({super.key, this.isMaterialsView = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => CollegeDataCubit()..getStudentSubjects(),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFFAF9F5),
        body: BlocBuilder<CollegeDataCubit, CollegeDataState>(
          builder: (context, state) {
            if (state is CollegeDataLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.kPrimaryColor));
            }

            final subjects = context.read<CollegeDataCubit>().filteredSubjects;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Premium SliverAppBar
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  stretch: true,
                  backgroundColor: AppColors.kPrimaryColor,
                  elevation: 0,
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    titlePadding: const EdgeInsets.only(bottom: 16),
                    title: Text(
                      isMaterialsView ? "study_materials".tr() : "my_subjects".tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: -0.3,
                        shadows: [Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8)],
                      ),
                    ),
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1E8449), Color(0xFF1E8449)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -50, right: -50,
                            child: Container(
                              width: 180, height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -20, left: -20,
                            child: Container(
                              width: 120, height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.03),
                              ),
                            ),
                          ),
                          // Center icon
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 28),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.08),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 2),
                                ),
                                child: Icon(
                                  isMaterialsView ? Icons.library_books_rounded : Icons.school_rounded,
                                  size: 36,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Section header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                isMaterialsView ? "academic_resources".tr() : "your_courses".tr(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                                  letterSpacing: -0.8,
                                ),
                              ),
                            ),
                            // Count badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.kPrimaryColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "${subjects.length}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.kPrimaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isMaterialsView
                              ? "access_lectures_desc".tr()
                              : "select_subject_desc".tr(),
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey.shade400,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: -0.1),
                ),

                // Grid of subjects
                if (subjects.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState(isDark))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.05,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final subject = subjects[index];
                          return SubjectCard(
                            subject: subject,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                RouteNames.subjectDetailsScreen,
                                arguments: subject.toJson(),
                              );
                            },
                          ).animate().fadeIn(delay: (80 * index).ms).scale(begin: const Offset(0.92, 0.92));
                        },
                        childCount: subjects.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LineIcons.book, size: 72, color: Colors.grey.withValues(alpha: 0.15)),
          const SizedBox(height: 20),
          Text(
            "No subjects found",
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey.shade400,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
