import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:line_icons/line_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_canvas/core/components/custom_text_form_field.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/admin/material/view_models/cubit/materials_cubit.dart';
import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';

class DoctorMaterialsHeader extends StatelessWidget {
  const DoctorMaterialsHeader({super.key});

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
            child: _buildDecorativeCircle(Colors.white.withValues(alpha: 0.05), 260)),
          Positioned(bottom: -40, right: -50,
            child: _buildDecorativeCircle(Colors.white.withValues(alpha: 0.04), 200)),
          Positioned(top: 50, right: 30,
            child: _buildDecorativeCircle(Colors.white.withValues(alpha: 0.03), 80)),
          // Diamond
          Positioned(
            top: 90, left: MediaQuery.of(context).size.width * 0.35,
            child: Transform.rotate(
              angle: 0.785, // pi/4
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(
              SizeConfig.w(5),
              SizeConfig.h(4),
              SizeConfig.w(5),
              SizeConfig.h(4)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: SizeConfig.h(2)),
                Row(
                  children: [
                    // Icon with glow
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.05),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.library_books_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "materials".tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Manage your course resources",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Add Subject Button
                    _buildAddButton(context),
                  ],
                ),
                SizedBox(height: SizeConfig.h(3.5)),

                // Premium Search & Stats
                _buildSearchAndStats(context, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeCircle(Color color, double size) {
    return Container(
      height: size, width: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildSearchAndStats(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Search bar with glow
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
            hintText: "Search for material...",
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1E1B15),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            onChanged: (value) {
              final cubit = context.read<MaterialsCubit>();
              cubit.searchMaterials(value);
              cubit.searchSubjects(value);
            },
          ),
        ),
        const SizedBox(height: 16),
        BlocBuilder<MaterialsCubit, MaterialsState>(
          builder: (context, state) {
            final cubit = context.read<MaterialsCubit>();
            final materialCount = cubit.filteredMaterials.length;
            final subjectCount = cubit.filteredProfessorSubjects.length;

            final showSubjectCount = cubit.materials.isEmpty && subjectCount >= 0;

            return Row(
              children: [
                // Count badge
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
                      Icon(
                        showSubjectCount ? Icons.school_rounded : Icons.description_rounded,
                        color: Colors.white, size: 15,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        showSubjectCount
                            ? "$subjectCount Subjects"
                            : "$materialCount Materials",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Quick info chip
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
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddSubjectDialog(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.05),
              blurRadius: 15,
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context) {
    final cubit = context.read<MaterialsCubit>();
    cubit.getAllSystemSubjects();
    
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    SubjectModel? selectedExistingSubject;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: StatefulBuilder(
          builder: (context, setState) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1B15) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2ECC71), Color(0xFF1E8449)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2ECC71).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Configure Subject",
                                style: TextStyle(
                                  fontSize: 22, 
                                  fontWeight: FontWeight.w900, 
                                  color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Select or create an academic course",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white38 : Colors.grey),
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    
                    // Existing Subject Selection
                    _buildSectionTitle("SELECT FROM DATABASE", isDark),
                    const SizedBox(height: 10),
                    BlocBuilder<MaterialsCubit, MaterialsState>(
                      builder: (context, state) {
                        final systemSubjects = cubit.allSystemSubjects;
                        return DropdownButtonFormField<SubjectModel>(
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF1E1B15) : Colors.white,
                          decoration: _inputDecoration(
                            systemSubjects.isEmpty ? "Fetching subjects..." : "Choose an existing subject", 
                            LineIcons.database, 
                            isDark
                          ),
                          hint: Text(
                            systemSubjects.isEmpty ? "Loading..." : "Pick a subject...",
                            style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          initialValue: selectedExistingSubject,
                          icon: systemSubjects.isEmpty 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2ECC71)))
                              : Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white38 : Colors.grey.shade500),
                          items: systemSubjects.map((s) => DropdownMenuItem(
                            value: s,
                            child: Text("${s.name} (${s.code ?? 'No Code'})", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          )).toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedExistingSubject = val;
                              if (val != null) {
                                nameController.text = val.name;
                                codeController.text = val.code ?? '';
                              }
                            });
                          },
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    // OR Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200, thickness: 1.2)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            "OR ADD NEW", 
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey.shade400, 
                              fontSize: 10, 
                              fontWeight: FontWeight.w900, 
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200, thickness: 1.2)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // New Subject Inputs
                    _buildSectionTitle("MANUAL ENTRY", isDark),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      decoration: _inputDecoration("Subject Name", LineIcons.heading, isDark),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: codeController,
                      decoration: _inputDecoration("Subject Code", LineIcons.code, isDark),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              "Discard",
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.grey.shade700,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2ECC71), Color(0xFF1E8449)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2ECC71).withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                if (nameController.text.isNotEmpty && codeController.text.isNotEmpty) {
                                  cubit.addSubject(nameController.text, codeController.text);
                                  Navigator.pop(dialogContext);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text(
                                "Confirm",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11, 
        fontWeight: FontWeight.w900, 
        color: isDark ? Colors.white54 : Colors.grey.shade600,
        letterSpacing: 1.5,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon, bool isDark) {
    const primaryColor = Color(0xFF1E8449);
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: isDark ? Colors.white38 : Colors.grey.shade400, size: 20),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F0E0A).withValues(alpha: 0.3) : const Color(0xFFFAF9F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.w500),
    );
  }
}
