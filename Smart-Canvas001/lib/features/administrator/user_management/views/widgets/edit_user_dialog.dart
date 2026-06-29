import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/components/custom_text_form_field_with_title.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/administrator/collages/models/collage_model.dart';
import 'package:smart_canvas/features/administrator/user_management/models/user_model.dart';
import 'package:smart_canvas/features/administrator/user_management/view_models/cubit/users_cubit.dart';

class EditUserDialog extends StatelessWidget {
  final UserModel user;
  
  const EditUserDialog({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final width = SizeConfig.width;
    final height = SizeConfig.height;
    final cubit = context.read<UsersCubit>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Load user data for editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cubit.loadUserForEdit(user);
    });

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: width * 0.05,
        vertical: height * 0.03,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: height * 0.9,
          maxWidth: width * 0.95,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppColors.kPrimaryColor).withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Premium Header
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.06,
                vertical: width * 0.05,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF2ECC71),
                    Color(0xFF1E8449),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: width * 0.06,
                    ),
                  ),
                  SizedBox(width: width * 0.05),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Specialist',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: width * 0.05,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Update user information and context',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: width * 0.03,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildHeaderCloseButton(context),
                ],
              ),
            ),
            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(width * 0.05),
                child: Form(
                  key: cubit.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name
                      CustomTextFormFieldWithTitle(
                        title: "Full Name",
                        controller: cubit.fullNameController,
                        hintText: "Enter full name",
                        prefixIcon: Icons.person_outline,
                      ),
                      SizedBox(height: height * 0.02),

                      // Email
                      CustomTextFormFieldWithTitle(
                        title: "Email",
                        controller: cubit.emailController,
                        hintText: "Enter email address",
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: height * 0.02),

                      // Phone
                      CustomTextFormFieldWithTitle(
                        title: "Phone Number",
                        controller: cubit.phoneController,
                        hintText: "Enter phone number",
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        enableValidator: false,
                      ),
                      SizedBox(height: height * 0.025),

                      // Password Reset Section
                      _buildSectionTitle(width, 'Reset Password', isDark),
                      SizedBox(height: height * 0.015),
                      Container(
                        padding: EdgeInsets.all(width * 0.04),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.red.shade900.withValues(alpha: 0.2) 
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark 
                                ? Colors.red.shade800.withValues(alpha: 0.3) 
                                : Colors.red.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber,
                                  color: Colors.red.shade400,
                                  size: width * 0.05,
                                ),
                                SizedBox(width: width * 0.02),
                                Expanded(
                                  child: Text(
                                    'Note: Passwords are encrypted and cannot be viewed',
                                    style: TextStyle(
                                      fontSize: width * 0.03,
                                      color: Colors.red.shade400,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: height * 0.015),
                            CustomTextFormFieldWithTitle(
                              title: "New Password",
                              controller: cubit.newPasswordController,
                              hintText: "Enter new password (leave empty to keep current)",
                              prefixIcon: Icons.lock_outline,
                              isPassword: true,
                              enableValidator: false,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: height * 0.025),

                      // Role Selection
                      _buildSectionTitle(width, 'Change Role', isDark),
                      SizedBox(height: height * 0.015),
                      BlocBuilder<UsersCubit, UsersState>(
                        buildWhen: (p, c) =>
                            c is RolesSuccess || 
                            c is RolesLoading || 
                            c is EditUserLoaded,
                        builder: (context, state) {
                          if (state is RolesLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return Wrap(
                            spacing: width * 0.025,
                            runSpacing: width * 0.025,
                            children: cubit.roles.map((role) {
                              final isSelected = cubit.selectedRoleId == role.id;
                              return GestureDetector(
                                onTap: () => cubit.selectRole(role.id),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.04,
                                    vertical: width * 0.025,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(
                                            colors: [
                                              AppColors.kPrimaryColor,
                                              AppColors.kPrimaryColor.withValues(alpha: 0.8),
                                            ],
                                          )
                                        : null,
                                    color: isSelected 
                                        ? null 
                                        : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.kPrimaryColor
                                          : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: width * 0.045,
                                        ),
                                      if (isSelected) SizedBox(width: width * 0.015),
                                      Text(
                                        role.name,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark ? Colors.white : Colors.black87),
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: width * 0.035,
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
                      SizedBox(height: height * 0.025),

                      // College Selection (for Students & Professors)
                      BlocBuilder<UsersCubit, UsersState>(
                        buildWhen: (p, c) =>
                            c is RolesSuccess ||
                            c is CollegesLoadedSuccess ||
                            c is AcademicYearsUpdated ||
                            c is EditUserLoaded,
                        builder: (context, state) {
                          final isStaff = cubit.isProfessorRole || cubit.isDoctorRole;
                          if (!cubit.isStudentRole && !isStaff && !cubit.isAdminRole) return const SizedBox();
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               // Academic ID / Staff ID
                               if (cubit.isStudentRole || isStaff) ...[
                                 CustomTextFormFieldWithTitle(
                                    title: cubit.isStudentRole ? "Student ID" : "Staff ID",
                                    controller: cubit.universityIdController,
                                    hintText: cubit.isStudentRole ? "Enter student ID" : "Enter staff ID",
                                    prefixIcon: Icons.badge_outlined,
                                    enableValidator: false,
                                  ),
                                  SizedBox(height: height * 0.02),
                               ],

                              _buildSectionTitle(width, 'Select College', isDark),
                              SizedBox(height: height * 0.015),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.04,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    hint: Text(
                                      'Select College',
                                      style: TextStyle(
                                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                      ),
                                    ),
                                    dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
                                    value: cubit.colleges.any((c) => c.id == cubit.selectedCollegeId) 
                                        ? cubit.selectedCollegeId 
                                        : null,
                                    items: cubit.colleges.map((college) {
                                      return DropdownMenuItem(
                                        value: college.id,
                                        child: Text(
                                          college.name,
                                          style: TextStyle(
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
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
                              SizedBox(height: height * 0.02),

                              // Specialization (Department)
                              if ((cubit.isStudentRole || cubit.isProfessorRole) && cubit.availableAcademicYears.isNotEmpty) ...[
                                _buildSectionTitle(width, 'Select Department', isDark),
                                SizedBox(height: height * 0.015),
                                Wrap(
                                  spacing: width * 0.025,
                                  runSpacing: width * 0.02,
                                  children: cubit.availableAcademicYears.map((year) {
                                    final isSelected = cubit.selectedAcademicYearId == year.id;
                                    return GestureDetector(
                                      onTap: () {
                                        cubit.selectAcademicYear(year.id);
                                                                            },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.035,
                                          vertical: width * 0.02,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.kPrimaryColor
                                              : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.kPrimaryColor
                                                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                          ),
                                        ),
                                        child: Text(
                                          year.name,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : (isDark ? Colors.white : Colors.black87),
                                            fontSize: width * 0.032,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                              SizedBox(height: height * 0.02),

                              // Academic Year selection (Only for Students) - STRICT FLOW
                              if (cubit.isStudentRole && 
                                  cubit.selectedCollegeId != null && 
                                  (cubit.selectedAcademicYearId != null || cubit.availableAcademicYears.isEmpty)) ...[
                                _buildSectionTitle(width, 'Select Academic Year', isDark),
                                SizedBox(height: height * 0.015),
                                BlocBuilder<UsersCubit, UsersState>(
                                  builder: (context, state) {
                                    final college = cubit.colleges.firstWhere(
                                      (c) => c.id == cubit.selectedCollegeId,
                                      orElse: () => CollegeModel(id: '', name: '', academicYears: [], abbreviation: '', image: '', createdAt: DateTime.now()),
                                    );
                                    if (college.id.isEmpty) return const SizedBox();
                                    
                                    final duration = college.durationYears ?? 4;
                                    
                                    return Wrap(
                                      spacing: width * 0.025,
                                      runSpacing: width * 0.02,
                                      children: List.generate(duration, (index) {
                                        final year = index + 1;
                                        final isSelected = cubit.selectedYear == year;
                                        return GestureDetector(
                                          onTap: () => cubit.selectYear(year),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: width * 0.035,
                                              vertical: width * 0.02,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.kPrimaryColor
                                                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppColors.kPrimaryColor
                                                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                              ),
                                            ),
                                            child: Text(
                                              "Year $year",
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.white
                                                    : (isDark ? Colors.white : Colors.black87),
                                                fontSize: width * 0.032,
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    );
                                  },
                                ),
                                SizedBox(height: height * 0.02),
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
              padding: EdgeInsets.all(width * 0.05),
              child: BlocBuilder<UsersCubit, UsersState>(
                buildWhen: (p, c) =>
                    c is UpdateUserLoading ||
                    c is UpdateUserSuccess ||
                    c is UpdateUserFailure,
                builder: (context, state) {
                  final isLoading = state is UpdateUserLoading;
                  return SizedBox(
                    width: double.infinity,
                    height: height * 0.065,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              await cubit.updateUser();
                              if (context.mounted) {
                                final currentState = cubit.state;
                                if (currentState is UpdateUserSuccess) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('User updated successfully!'),
                                      backgroundColor: Colors.green.shade600,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                } else if (currentState is UpdateUserFailure) {
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF1E8449),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: const Color(0xFF1E8449).withValues(alpha: 0.4),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Save Changes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: width * 0.045,
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

  Widget _buildSectionTitle(double width, String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: width * 0.038,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white70 : Colors.black54,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildHeaderCloseButton(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.pop(context),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}
