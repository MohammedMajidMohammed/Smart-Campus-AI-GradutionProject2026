import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/core/components/custom_text_form_field.dart';
import 'package:smart_canvas/features/admin/material/view_models/cubit/materials_cubit.dart';
import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';

class SubjectDetailsHeader extends StatelessWidget {
  final SubjectModel subject;
  
  const SubjectDetailsHeader({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF1E8449)).withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0F0E0A), const Color(0xFF1E1B15)]
              : [const Color(0xFF1E8449), const Color(0xFF2ECC71), const Color(0xFF0E6251)],
          stops: isDark ? null : const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative geometry
          Positioned(top: -80, left: -60,
            child: Container(
              height: 260, width: 260,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(bottom: -40, right: -50,
            child: Container(
              height: 200, width: 200,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(top: 50, right: 30,
            child: Container(
              height: 80, width: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      
                      // Info Button
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(LineIcons.infoCircle, color: Colors.white, size: 22),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Subject Title
                  Text(
                    subject.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Subtitles / College & Year Info
                  Row(
                    children: [
                      if (subject.code != null && subject.code!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            subject.code!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          subject.college?.name ?? "Academic Course",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 28),

                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CustomTextFormField(
                      prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white54 : Colors.grey[400], size: 22),
                      fillColor: isDark ? const Color(0xFF2A2720) : Colors.white,
                      hintText: "Search files inside folder...",
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E1B15),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      onChanged: (value) {
                        final cubit = context.read<MaterialsCubit>();
                        cubit.searchMaterials(value);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Statistics Badge
                  BlocBuilder<MaterialsCubit, MaterialsState>(
                    builder: (context, state) {
                      final cubit = context.read<MaterialsCubit>();
                      final materialCount = cubit.filteredMaterials.length;
                      
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.description_rounded, color: Colors.white, size: 15),
                                const SizedBox(width: 8),
                                Text(
                                  "$materialCount Resources",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.cloud_done_rounded, color: Colors.white.withValues(alpha: 0.7), size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  "Synced",
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w700, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
