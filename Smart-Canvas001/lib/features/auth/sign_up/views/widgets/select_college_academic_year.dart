import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:smart_canvas/features/auth/sign_up/view_models/cubit/sign_up_cubit.dart';

class SelectAcademicYear extends StatelessWidget {
  const SelectAcademicYear({
    super.key,
    required this.cubit,
  });

  final SignUpCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignUpCubit, SignUpState>(
      buildWhen: (previous, current) =>
          current is GetAcademicYearsSuccess ||
          current is AcademicYearsUpdated,
      builder: (context, state) {
        if (cubit.availableAcademicYears.isEmpty) {
          return const SizedBox.shrink(); // Hide if no years available yet
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Academic Year *",
              style: AppTextStyles.title14Black,
            ),
            SizedBox(height: SizeConfig.height * 0.01),
            Wrap(
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
            ),
            if (cubit.academicYearId == null || cubit.academicYearId!.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: SizeConfig.height * 0.005),
                child: const Text(
                  "Please select an academic year",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}