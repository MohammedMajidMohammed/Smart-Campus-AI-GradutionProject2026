import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/administrator/collages/models/academic_year_model.dart';
import 'package:smart_canvas/features/administrator/collages/models/collage_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/features/administrator/collages/view_models/cubit/colleges_cubit.dart';
import 'package:smart_canvas/features/administrator/collages/view_models/cubit/add_college_cubit.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/add_college_modal_bottom_sheet_body.dart';

class CollageDetailsModelBottomSheetBody extends StatelessWidget {
  const CollageDetailsModelBottomSheetBody({super.key, required this.collage});
  final CollegeModel collage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1B15) : const Color(0xFFFAF9F5),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Custom Handle Bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Banner / Image Section
                          Center(
                            child: Container(
                              width: double.infinity,
                              height: 240,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(35),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.kPrimaryColor.withValues(alpha: 0.2),
                                    blurRadius: 25,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(35),
                                child: Image.network(
                                  collage.image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: Colors.grey[200],
                                        child: Icon(Icons.school_rounded, size: 80, color: AppColors.kPrimaryColor.withValues(alpha: 0.5)),
                                      ),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 28),
                          
                          // Header Info
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      collage.name,
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Faculty established in ${collage.createdAt.year}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.kPrimaryColor,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.kPrimaryColor.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  collage.abbreviation,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 32),
                          
                          // Info Sections
                          _InfoGrid(collage: collage),
                          
                          const SizedBox(height: 32),
                          
                          // Academic Years Badge Section
                          const _SectionHeader(title: "Academic Years Paths", icon: Icons.auto_awesome_mosaic_rounded),
                          const SizedBox(height: 16),
                          _AcademicYearsWrap(academicYears: collage.academicYears ?? []),
                          
                          const SizedBox(height: 32),
                          
                          // Management Section
                          const _SectionHeader(title: "Logistics Details", icon: Icons.admin_panel_settings_rounded),
                          const SizedBox(height: 16),
                          _LogisticsCard(collage: collage),
                        ],
                      ),
                    ),
                    
                    // Close Button Floating
                    Positioned(
                      top: 10,
                      right: 20,
                      child: _CircleActionButton(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.pop(context),
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    
                    // Edit Button Floating
                    Positioned(
                      top: 10,
                      left: 20,
                      child: _CircleActionButton(
                        icon: Icons.edit_note_rounded,
                        onTap: () {
                          showModalBottomSheet(
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            context: context,
                            builder: (childContext) => BlocProvider.value(
                              value: context.read<CollegesCubit>(),
                              child: BlocProvider(
                                create: (childContext) => AddCollegeCubit(
                                  collegesCubit: childContext.read<CollegesCubit>(),
                                )..initEdit(collage),
                                child: const AddCollageBottomSheet(),
                              ),
                            ),
                          );
                        },
                        color: AppColors.kPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.kPrimaryColor),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.grey[400] : Colors.grey[500],
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final CollegeModel collage;
  const _InfoGrid({required this.collage});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            title: "Study Period",
            value: "${collage.durationYears ?? 4} Years",
            icon: Icons.timer_rounded,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _InfoCard(
            title: "Internship",
            value: "${collage.internshipYears ?? 0} Year${(collage.internshipYears ?? 0) > 1 ? 's' : ''}",
            icon: Icons.workspace_premium_rounded,
            color: Colors.orangeAccent,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[500])),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1F2937))),
        ],
      ),
    );
  }
}

class _AcademicYearsWrap extends StatelessWidget {
  final List<AcademicYearModel> academicYears;
  const _AcademicYearsWrap({required this.academicYears});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: academicYears.map((year) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.kPrimaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.kPrimaryColor.withValues(alpha: 0.1)),
          ),
          child: Text(
            year.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.kPrimaryColor,
            ),
          ),
        )).toList(),
      ),
    );
  }
}

class _LogisticsCard extends StatelessWidget {
  final CollegeModel collage;
  const _LogisticsCard({required this.collage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.kPrimaryColor, AppColors.kPrimaryColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_edu_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "System Management",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white70),
                ),
                const SizedBox(height: 2),
                Text(
                  "Verified on ${collage.createdAt.day}/${collage.createdAt.month}/${collage.createdAt.year}",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _CircleActionButton({required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1B15) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}


