import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:smart_canvas/features/administrator/schedule/view_models/cubit/add_subject_schedule_cubit.dart';

class TimeSelector extends StatelessWidget {
  const TimeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AddSubjectScheduleCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Time Duration', style: AppTextStyles.title18BlackW600),
        SizedBox(height: SizeConfig.height * 0.015),
        BlocBuilder<AddSubjectScheduleCubit, AddSubjectScheduleState>(
          buildWhen: (p, c) => c is UpdateTimeSlot,
          builder: (context, state) {
            return Row(
              children: [
                Expanded(
                  child: _buildTimePickerCard(
                    context: context,
                    title: 'From',
                    time: cubit.startTime,
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: cubit.startTime ?? const TimeOfDay(hour: 9, minute: 0),
                      );
                      if (time != null) {
                        cubit.setStartTime(time);
                      }
                    },
                  ),
                ),
                SizedBox(width: SizeConfig.width * 0.04),
                Expanded(
                  child: _buildTimePickerCard(
                    context: context,
                    title: 'To',
                    time: cubit.endTime,
                    isEnd: true,
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: cubit.endTime ?? const TimeOfDay(hour: 11, minute: 0),
                      );
                      if (time != null) {
                        cubit.setEndTime(time);
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimePickerCard({
    required BuildContext context,
    required String title,
    required TimeOfDay? time,
    required VoidCallback onTap,
    bool isEnd = false,
  }) {
    // Format Time: 08:30 AM
    String formattedTime = 'Select Time';
    Color textColor = Colors.grey;
    
    if (time != null) {
        final now = DateTime.now();
        final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        final hour = dt.hour == 0 || dt.hour == 12 ? 12 : dt.hour % 12;
        final minute = dt.minute.toString().padLeft(2, '0');
        final period = dt.hour < 12 ? 'AM' : 'PM';
        formattedTime = "${hour.toString().padLeft(2, '0')}:$minute $period";
        textColor = AppColors.kPrimaryColor;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: time != null ? AppColors.kPrimaryColor : Colors.grey.withValues(alpha: 0.3),
            width: time != null ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isEnd ? Icons.event_busy_outlined : Icons.access_time_filled_rounded,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: AppTextStyles.title14Grey.copyWith(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formattedTime,
              style: AppTextStyles.title16BlackBold.copyWith(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
