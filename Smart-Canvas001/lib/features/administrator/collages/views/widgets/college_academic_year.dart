import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/components/custom_circular_progress_indecator.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/administrator/collages/view_models/cubit/add_college_cubit.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/custom_failure_message.dart';

class CollegeAcademicYear extends StatelessWidget {
  const CollegeAcademicYear({super.key, required this.cubit});

  final AddCollegeCubit cubit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Academic Years', 
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        BlocBuilder<AddCollegeCubit, AddCollegeState>(
          buildWhen: (previous, current) =>
              current is AcademicYearsUpdated ||
              current is GetAcademicYearsError ||
              current is GetAcademicYearsLoading ||
              current is GetAcademicYearsSuccess,
          builder: (context, state) {
            if (state is GetAcademicYearsError) {
              return CustomFailureMesage(errorMessage: state.message);
            }
            if (state is GetAcademicYearsLoading) {
              return const CustomCircularProgresIndecator();
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cubit.availableAcademicYears.map((year) {
                final isSelected = cubit.selectedAcademicYears.contains(year);
                return ChoiceChip(
                  showCheckmark: true,
                  checkmarkColor: Colors.white,
                  label: Text(
                    year.name,
                    style: TextStyle(
                      color: isSelected 
                          ? Colors.white 
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.kPrimaryColor,
                  backgroundColor: isDark ? const Color(0xFF1E1B15) : Colors.grey.shade100,
                  onSelected: (_) => cubit.toggleAcademicYear(year),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected 
                          ? AppColors.kPrimaryColor 
                          : (isDark ? Colors.white10 : Colors.grey.shade300),
                      width: 1,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
