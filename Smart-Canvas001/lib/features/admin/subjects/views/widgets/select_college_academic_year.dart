import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:smart_canvas/features/admin/subjects/view_models/cubit/add_subject_cubit.dart';

class SelectCollegeAcademicYear extends StatelessWidget {
  const SelectCollegeAcademicYear({
    super.key,
    required this.cubit,
  });

  final AddSubjectCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddSubjectCubit, AddSubjectState>(
      buildWhen: (previous, current) =>
          current is GetAcademicYearsSuccess ||
          current is AcademicYearsUpdated,
      builder: (context, state) {
        return Wrap(
          spacing: SizeConfig.width * 0.02,
          children: cubit.availableAcademicYears.map((year) {
            final isSelected = cubit.selectedAcademicYears.contains(year);
            return ChoiceChip(
              checkmarkColor: Colors.white,
              label: Text(
                year.name,
                style: AppTextStyles.title14Black.copyWith(
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.kPrimaryColor,
              backgroundColor: Colors.grey.shade200,
              onSelected: (_) => cubit.toggleAcademicYear(year),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
