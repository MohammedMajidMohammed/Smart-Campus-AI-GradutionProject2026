import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/components/custom_circular_progress_indecator.dart';
import 'package:smart_canvas/core/components/custom_text_form_field_with_title.dart';
import 'package:smart_canvas/features/administrator/collages/view_models/cubit/add_college_cubit.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/college_academic_year.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/college_image.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';

class AddCollageForm extends StatelessWidget {
  const AddCollageForm({super.key});

  @override
  Widget build(BuildContext context) {
    var cubit = context.read<AddCollegeCubit>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = cubit.collegeId != null;

    return Form(
      key: cubit.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sleek Elegant Header
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isEdit ? Icons.edit_note : Icons.school_sharp,
                  color: AppColors.kPrimaryColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Edit College' : 'Add New College',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEdit 
                        ? 'Modify the details of this university college'
                        : 'Register and set up a new university college',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          CustomTextFormFieldWithTitle(
            prefixIcon: Icons.school_outlined,
            title: 'Name',
            controller: cubit.collegeNameController,
            hintText: 'Enter college name',
          ),
          const SizedBox(height: 16),
          CustomTextFormFieldWithTitle(
            title: 'Abbreviation',
            prefixIcon: Icons.short_text_rounded,
            hintText: 'Enter abbreviation (e.g. FCAI)',
            controller: cubit.collegeAbbreviationController,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextFormFieldWithTitle(
                  title: 'Duration (Years)',
                  prefixIcon: Icons.timer_outlined,
                  hintText: '4',
                  keyboardType: TextInputType.number,
                  controller: cubit.durationController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextFormFieldWithTitle(
                  title: 'Internship (Years)',
                  prefixIcon: Icons.health_and_safety_outlined,
                  hintText: '0',
                  keyboardType: TextInputType.number,
                  controller: cubit.internshipController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const CollegeImage(),
          const SizedBox(height: 20),
          CollegeAcademicYear(cubit: cubit),
          const SizedBox(height: 35),
          BlocBuilder<AddCollegeCubit, AddCollegeState>(
            buildWhen: (previous, current) =>
                current is AddCollegeSuccess ||
                current is AddCollegeError ||
                current is AddCollegeLoading,
            builder: (context, state) {
              return state is AddCollegeLoading
                  ? const CustomCircularProgresIndecator()
                  : Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.kPrimaryColor,
                            AppColors.kPrimaryColor.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.kPrimaryColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          cubit.addCollege();
                        },
                        icon: Icon(isEdit ? Icons.save : Icons.add, size: 20),
                        label: Text(
                          isEdit ? 'Update College' : 'Add College',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    );
            },
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }
}
