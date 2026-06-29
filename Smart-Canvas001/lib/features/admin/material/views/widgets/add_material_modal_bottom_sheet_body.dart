import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/core/components/custom_text_form_field_with_title.dart';
import 'package:smart_canvas/features/admin/material/view_models/cubit/add_material_cubit.dart';

class AddMaterialModalBottomSheetBody extends StatelessWidget {
  const AddMaterialModalBottomSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<AddMaterialCubit>();

    return BlocListener<AddMaterialCubit, AddMaterialState>(
      listener: (context, state) {
        if (state is AddMaterialSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Published successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        } else if (state is AddMaterialError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is SelectSubject) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please wait, subject not selected'), backgroundColor: Colors.orange),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24, right: 24, top: 12
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1B15) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 40, offset: const Offset(0, -10)),
          ],
        ),
        child: SingleChildScrollView(
          child: BlocBuilder<AddMaterialCubit, AddMaterialState>(
            builder: (context, state) {
              return Form(
                key: cubit.formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 50, height: 6,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10)
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Header section
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(LineIcons.plusCircle, color: Color(0xFF2ECC71), size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Publish Content",
                                style: TextStyle(
                                  fontSize: 22, 
                                  fontWeight: FontWeight.w900, 
                                  color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Upload lectures and materials for students",
                                style: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.grey.shade500, 
                                  fontSize: 12, 
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Lecture vs Section
                    _buildCategorySelector(context, cubit, isDark),
                    const SizedBox(height: 24),

                    // Folder Name / Chapter
                    CustomTextFormFieldWithTitle(
                      title: "Folder / Module Name",
                      hintText: "e.g. Chapter 1, Database Systems...",
                      controller: cubit.folderNameController,
                      prefixIcon: LineIcons.folder,
                    ),
                    const SizedBox(height: 24),

                    // Resource Type Selector
                    _buildTypeToggle(context, cubit, isDark),
                    const SizedBox(height: 20),

                    // Conditional Input
                    cubit.isLink 
                      ? Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.green.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: CustomTextFormFieldWithTitle(
                            title: "Google Drive / Cloud Link",
                            hintText: "https://drive.google.com/...",
                            controller: cubit.linkController,
                            prefixIcon: LineIcons.link,
                          ),
                        )
                      : _buildFilePicker(cubit, isDark),
                    
                    const SizedBox(height: 36),

                    // Professional Action Button
                    Container(
                      width: double.infinity,
                      height: 56,
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
                        onPressed: () => cubit.addMaterial(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          state is AddMaterialLoading ? "COMMITTING..." : "PUBLISH NOW",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context, AddMaterialCubit cubit, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ACADEMIC CATEGORY",
          style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 11, letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _categoryOption(cubit, "Lecture", LineIcons.chalkboard, cubit.materialType == "Lecture", isDark),
            const SizedBox(width: 16),
            _categoryOption(cubit, "Section", LineIcons.users, cubit.materialType == "Section", isDark),
          ],
        ),
      ],
    );
  }

  Widget _categoryOption(AddMaterialCubit cubit, String label, IconData icon, bool isSelected, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: () => cubit.setMaterialType(label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF2ECC71), Color(0xFF1E8449)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFFAF9F5)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF2ECC71).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon, 
                color: isSelected ? Colors.white : (isDark ? Colors.white38 : Colors.grey.shade500), 
                size: 26
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900, 
                  color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.grey.shade700),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle(BuildContext context, AddMaterialCubit cubit, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "RESOURCE TECHNOLOGY",
          style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 11, letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _typeOption(cubit, "Local Storage", LineIcons.hdd, !cubit.isLink, isDark, false),
            const SizedBox(width: 16),
            _typeOption(cubit, "Cloud Drive", LineIcons.cloud, cubit.isLink, isDark, true),
          ],
        ),
      ],
    );
  }

  Widget _typeOption(AddMaterialCubit cubit, String label, IconData icon, bool isActive, bool isDark, bool value) {
    return Expanded(
      child: InkWell(
        onTap: () => cubit.toggleIsLink(value),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFF2ECC71), Color(0xFF1E8449)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive ? null : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFFAF9F5)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? Colors.transparent : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200),
              width: 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF2ECC71).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon, 
                color: isActive ? Colors.white : (isDark ? Colors.white38 : Colors.grey.shade500), 
                size: 18
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900, 
                  color: isActive ? Colors.white : (isDark ? Colors.white60 : Colors.grey.shade700), 
                  fontSize: 12
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePicker(AddMaterialCubit cubit, bool isDark) {
    return InkWell(
      onTap: () => cubit.pickFile(),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFF2ECC71).withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF2ECC71).withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2ECC71), Color(0xFF1E8449)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2ECC71).withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(LineIcons.upload, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 18),
                Text(
                  cubit.selectedFileName ?? "Tap to select document",
                  style: TextStyle(
                    fontWeight: FontWeight.w800, 
                    color: cubit.selectedFileName != null ? const Color(0xFF1E8449) : (isDark ? Colors.white70 : const Color(0xFF1E1B15)),
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  "PDF, DOCX, PPTX OR SYSTEM FILES", 
                  style: TextStyle(
                    color: isDark ? Colors.white30 : Colors.grey.shade500, 
                    fontSize: 10, 
                    fontWeight: FontWeight.w800, 
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
