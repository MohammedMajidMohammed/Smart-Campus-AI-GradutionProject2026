import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/theme/app_theme.dart';
import 'package:smart_canvas/features/administrator/buildings/views/widgets/wave_image.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/search_and_filter.dart';
import 'package:smart_canvas/features/professor/schedule/view_models/cubit/professor_schedule_cubit.dart';

class ProfessorSchedulesHeader extends StatelessWidget {
  const ProfessorSchedulesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(SizeConfig.w(6)),
          bottomRight: Radius.circular(SizeConfig.w(6)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Opacity(
            opacity: 0.15,
            child: WaveImage(
              color: Colors.white,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + SizeConfig.h(2),
              left: SizeConfig.w(5),
              right: SizeConfig.w(5),
              bottom: SizeConfig.h(3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Management Schedule",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_calendar_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.h(2.5)),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SearchAndFilter(
                    hintText: "Search for subjects...",
                    onChanged: (value) {
                      context.read<ProfessorScheduleCubit>().searchSchedules(value);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
