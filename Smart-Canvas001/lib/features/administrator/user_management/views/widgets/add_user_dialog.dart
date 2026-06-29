import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/components/custom_text_form_field_with_title.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/administrator/user_management/view_models/cubit/users_cubit.dart';

class AddUserDialog extends StatelessWidget {
  const AddUserDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UsersCubit>();

    // Always fetch latest data when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (cubit.roles.isEmpty) {
        cubit.fetchRoles();
      }
      cubit.fetchColleges();
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 32,
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 680,
          maxWidth: 420,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F0E0A) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Elegant horizontal row header inside dialog
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E8449).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: Color(0xFF1E8449),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New User',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Fill in the specialist details',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildHeaderCloseButton(context, isDark),
                ],
              ),
            ),
            
            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Form(
                  key: cubit.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Image Picker
                      BlocBuilder<UsersCubit, UsersState>(
                        builder: (context, state) {
                          return Center(
                            child: GestureDetector(
                              onTap: cubit.pickProfileImage,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                                      border: Border.all(
                                        color: AppColors.kPrimaryColor.withValues(alpha: 0.2),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.kPrimaryColor.withValues(alpha: 0.08),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: cubit.selectedImage != null
                                        ? ClipOval(
                                            child: Image.file(
                                              cubit.selectedImage!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.add_a_photo_rounded,
                                                  size: 24,
                                                  color: AppColors.kPrimaryColor,
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Add Photo',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.kPrimaryColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                  if (cubit.selectedImage != null)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.kPrimaryColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: isDark ? const Color(0xFF0F0E0A) : Colors.white, width: 2),
                                        ),
                                        child: const Icon(Icons.edit, color: Colors.white, size: 12),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Full Name
                      CustomTextFormFieldWithTitle(
                        title: "Full Name",
                        controller: cubit.fullNameController,
                        hintText: "Enter full name",
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 14),

                      // Email
                      CustomTextFormFieldWithTitle(
                        title: "Email",
                        controller: cubit.emailController,
                        hintText: "Enter email address",
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),

                      // Phone
                      CustomTextFormFieldWithTitle(
                        title: "Phone Number",
                        controller: cubit.phoneController,
                        hintText: "Enter phone number",
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        enableValidator: false,
                      ),
                      const SizedBox(height: 14),

                      // Password
                      CustomTextFormFieldWithTitle(
                        title: "Password",
                        controller: cubit.passwordController,
                        hintText: "Enter password",
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                      ),
                      const SizedBox(height: 20),

                      // Role Selection
                      _buildSectionTitle('Select Role', isDark),
                      const SizedBox(height: 10),
                      BlocBuilder<UsersCubit, UsersState>(
                        buildWhen: (p, c) =>
                            c is RolesSuccess || c is RolesLoading,
                        builder: (context, state) {
                          if (state is RolesLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          if (cubit.roles.isEmpty) {
                            return Center(
                              child: Column(
                                children: [
                                  Text("No roles found", style: TextStyle(color: Colors.grey.shade600)),
                                  TextButton(
                                    onPressed: () => cubit.fetchRoles(),
                                    child: const Text("Retry loading roles"),
                                  )
                                ],
                              ),
                            );
                          }

                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: cubit.roles.map((role) {
                              final isSelected = cubit.selectedRoleId == role.id;
                              final roleIcon = _getRoleIcon(role.name);
                              final roleColors = _getRoleColors(role.name);
                              
                              return GestureDetector(
                                onTap: () => cubit.selectRole(role.id),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: isSelected 
                                        ? LinearGradient(colors: roleColors) 
                                        : null,
                                    color: isSelected 
                                        ? null 
                                        : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected 
                                          ? roleColors[0].withValues(alpha: 0.5) 
                                          : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade300),
                                      width: 1.5,
                                    ),
                                    boxShadow: isSelected ? [
                                      BoxShadow(
                                        color: roleColors[0].withValues(alpha: 0.25),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ] : [],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        roleIcon,
                                        color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        role.name,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // College Selection (for Students & Professors)
                      BlocBuilder<UsersCubit, UsersState>(
                        buildWhen: (p, c) =>
                            c is RolesSuccess ||
                            c is CollegesLoadedSuccess ||
                            c is AcademicYearsUpdated,
                        builder: (context, state) {
                          if (!cubit.isStudentRole && !cubit.isProfessorRole && !cubit.isAdminRole) return const SizedBox();
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Student ID (only for students)
                              if (cubit.isStudentRole) ...[
                                CustomTextFormFieldWithTitle(
                                  title: "Student ID",
                                  controller: cubit.universityIdController,
                                  hintText: "Enter student ID",
                                  prefixIcon: Icons.badge_outlined,
                                  enableValidator: false,
                                ),
                                const SizedBox(height: 14),
                              ],

                              Row(
                                children: [
                                  _buildSectionTitle('Select College', isDark),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.refresh, size: 18),
                                    onPressed: () => cubit.fetchColleges(),
                                    tooltip: "Refresh Colleges",
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    dropdownColor: isDark ? const Color(0xFF0F0E0A) : Colors.white,
                                    hint: Text(
                                      'Select College',
                                      style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14),
                                    ),
                                    value: cubit.selectedCollegeId,
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                                    items: cubit.colleges.map((college) {
                                      return DropdownMenuItem(
                                        value: college.id,
                                        child: Text(college.name),
                                      );
                                    }).toList(),
                                    onChanged: (collegeId) {
                                      if (collegeId != null) {
                                        final college = cubit.colleges.firstWhere((c) => c.id == collegeId);
                                        cubit.selectCollege(college);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Specialization (Department)
                              if ((cubit.isStudentRole || cubit.isProfessorRole) && cubit.availableAcademicYears.isNotEmpty) ...[
                                _buildSectionTitle('Select Department', isDark),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: cubit.availableAcademicYears.map((year) {
                                    final isSelected = cubit.selectedAcademicYearId == year.id;
                                    return GestureDetector(
                                      onTap: () {
                                        cubit.selectAcademicYear(year.id);
                                                                            },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.kPrimaryColor
                                              : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.kPrimaryColor
                                                : (isDark ? Colors.white10 : Colors.grey.shade300),
                                          ),
                                        ),
                                        child: Text(
                                          year.name,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : (isDark ? Colors.white70 : Colors.black87),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                              const SizedBox(height: 14),

                              // Academic Year selection (Only for Students) - STRICT FLOW
                              if (cubit.isStudentRole && 
                                  cubit.selectedCollegeId != null && 
                                  (cubit.selectedAcademicYearId != null || cubit.availableAcademicYears.isEmpty)) ...[
                                _buildSectionTitle('Select Academic Year', isDark),
                                const SizedBox(height: 8),
                                BlocBuilder<UsersCubit, UsersState>(
                                  builder: (context, state) {
                                    final college = cubit.colleges.firstWhere(
                                      (c) => c.id == cubit.selectedCollegeId,
                                    );
                                    final duration = college.durationYears ?? 4;
                                    
                                    return Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: List.generate(duration, (index) {
                                        final year = index + 1;
                                        final isSelected = cubit.selectedYear == year;
                                        return GestureDetector(
                                          onTap: () => cubit.selectYear(year),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.kPrimaryColor
                                                  : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppColors.kPrimaryColor
                                                    : (isDark ? Colors.white10 : Colors.grey.shade300),
                                              ),
                                            ),
                                            child: Text(
                                              "Year $year",
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.white
                                                    : (isDark ? Colors.white70 : Colors.black87),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    );
                                  },
                                ),
                                const SizedBox(height: 14),
                              ],
                            ],
                          );
                        },
                      ),

                    ],
                  ),
                ),
              ),
            ),
            
            // Submit Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: BlocBuilder<UsersCubit, UsersState>(
                buildWhen: (p, c) =>
                    c is CreateUserLoading ||
                    c is CreateUserSuccess ||
                    c is CreateUserFailure,
                builder: (context, state) {
                  final isLoading = state is CreateUserLoading;
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              await cubit.createUser();
                              if (context.mounted) {
                                final currentState = cubit.state;
                                if (currentState is CreateUserSuccess) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('User created successfully!'),
                                      backgroundColor: Colors.green.shade600,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                } else if (currentState is CreateUserFailure) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(currentState.message),
                                      backgroundColor: Colors.red.shade600,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.kPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.kPrimaryColor.withValues(alpha: 0.3),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Create User',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white70 : Colors.black54,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildHeaderCloseButton(BuildContext context, bool isDark) {
    return IconButton(
      onPressed: () => Navigator.pop(context),
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.close_rounded,
          color: isDark ? Colors.white60 : Colors.black54,
          size: 16,
        ),
      ),
    );
  }

  IconData _getRoleIcon(String? roleName) {
    switch (roleName?.toLowerCase()) {
      case 'admin':
      case 'administrator':
        return Icons.admin_panel_settings_rounded;
      case 'professor':
        return Icons.school_rounded;
      case 'student':
        return Icons.person_rounded;
      case 'doctor':
        return Icons.medical_services_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  List<Color> _getRoleColors(String? roleName) {
    switch (roleName?.toLowerCase()) {
      case 'admin':
      case 'administrator':
        return [const Color(0xFF2ECC71), const Color(0xFF1E8449)];
      case 'professor':
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case 'student':
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case 'doctor':
        return [const Color(0xFF1E8449), const Color(0xFF1E8449)];
      default:
        return [const Color(0xFF94A3B8), const Color(0xFF64748B)];
    }
  }
}
