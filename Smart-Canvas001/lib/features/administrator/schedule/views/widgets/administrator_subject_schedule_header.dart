import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/features/administrator/collages/views/widgets/search_and_filter.dart';
import 'package:smart_canvas/core/components/custom_drop_down_button_form_field.dart';
import 'package:smart_canvas/features/administrator/schedule/view_models/cubit/schedules_cubit.dart';

class AdministratorSubjectScheduleHeader extends StatefulWidget {
  const AdministratorSubjectScheduleHeader({super.key});

  @override
  State<AdministratorSubjectScheduleHeader> createState() =>
      _AdministratorSubjectScheduleHeaderState();
}

class _AdministratorSubjectScheduleHeaderState
    extends State<AdministratorSubjectScheduleHeader> {
  bool _showFilters = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16, right: 16, bottom: 18,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : const Color(0xFF1E8449),
        gradient: LinearGradient(
          colors: isDark 
              ? [const Color(0xFF1E1B15), const Color(0xFF0F0E0A)]
              : [const Color(0xFF1E8449), const Color(0xFF1E8449)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: BlocBuilder<SchedulesCubit, SchedulesState>(
        builder: (context, state) {
          final cubit = context.read<SchedulesCubit>();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopRow(context, cubit, isDark),
              const SizedBox(height: 14),
              SearchAndFilter(
                hintText: "Search for subjects",
                onPressedFilter: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                onChanged: (value) {
                  cubit.searchSchedules(value);
                },
              ),
              
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    const SizedBox(height: 14),
                    // Filter: College
                    CustomDropDownButtonFormField(
                      title: 'College',
                      hintText: 'All Colleges',
                      prefixIcon: Icons.account_balance_rounded,
                      items: cubit.colleges,
                      itemLabelBuilder: (e) => e.name,
                      onChanged: (value) => cubit.selectCollege(value),
                      value: cubit.selectedCollege,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.12),
                      textColor: Colors.white,
                      iconColor: Colors.white70,
                      titleColor: Colors.white.withValues(alpha: 0.9),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Filter: Program
                        Expanded(
                          flex: 2,
                          child: CustomDropDownButtonFormField(
                            title: 'Program',
                            hintText: 'All Programs',
                            prefixIcon: Icons.layers_rounded,
                            items: cubit.programs,
                            itemLabelBuilder: (e) => e.name,
                            onChanged: (value) => cubit.selectProgram(value),
                            value: cubit.selectedProgram,
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.12),
                            textColor: Colors.white,
                            iconColor: Colors.white70,
                            titleColor: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Filter: Year Level
                        Expanded(
                          flex: 1,
                          child: CustomDropDownButtonFormField(
                            title: 'Year',
                            hintText: 'All',
                            prefixIcon: Icons.school_rounded,
                            items: const [1, 2, 3, 4, 5, 6, 7],
                            itemLabelBuilder: (e) => 'Y$e',
                            onChanged: (value) => cubit.selectYearLevel(value),
                            value: cubit.selectedYearLevel,
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.12),
                            textColor: Colors.white,
                            iconColor: Colors.white70,
                            titleColor: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                crossFadeState: _showFilters 
                    ? CrossFadeState.showSecond 
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopRow(BuildContext context, SchedulesCubit cubit, bool isDark) {
    final canPop = Navigator.canPop(context);
    final count = cubit.filteredSchedules.length;

    return Row(
      children: [
        if (canPop) ...[
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Management Schedule",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "$count Classes",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "•",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  const Text(
                    "Live Updates",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.event_note_rounded, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}
