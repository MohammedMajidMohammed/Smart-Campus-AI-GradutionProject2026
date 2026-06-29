import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/constants/app_constants.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:smart_canvas/features/administrator/schedule/view_models/cubit/add_subject_schedule_cubit.dart';

class DaySelector extends StatelessWidget {
  const DaySelector({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AddSubjectScheduleCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Day', style: AppTextStyles.title18BlackW600),
        SizedBox(height: SizeConfig.height * 0.015),
        BlocBuilder<AddSubjectScheduleCubit, AddSubjectScheduleState>(
          buildWhen: (p, c) => c is UpdateDayOfWeek,
          builder: (context, state) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: AppConstants.days.map((day) {
                  final isSelected = cubit.dayOfWeek == day;
                  return GestureDetector(
                    onTap: () => cubit.selectDay(day: day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.kPrimaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.kPrimaryColor : Colors.grey.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.kPrimaryColor.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                )
                              ],
                      ),
                      child: Text(
                        day,
                        style: isSelected
                            ? AppTextStyles.title16WhiteW600
                            : AppTextStyles.title16Black54,
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}
