import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/components/custom_circular_progress_indecator.dart';
import 'package:smart_canvas/core/components/custom_drop_down_button_form_field.dart';
import 'package:smart_canvas/features/administrator/schedule/view_models/cubit/add_subject_schedule_cubit.dart';
import 'package:smart_canvas/features/administrator/schedule/views/widgets/day_selector.dart';
import 'package:smart_canvas/features/administrator/rooms/models/room_model.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/administrator/schedule/views/widgets/timer_selector.dart';

class AddSubjectScheduleForm extends StatelessWidget {
  const AddSubjectScheduleForm({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AddSubjectScheduleCubit>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AddSubjectScheduleCubit, AddSubjectScheduleState>(
      buildWhen: (p, c) => c is GetCollegesLoading || c is GetCollegesSuccess || c is GetCollegesError,
      builder: (context, state) {
        if (state is GetCollegesLoading && cubit.colleges.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 50),
              child: CustomCircularProgresIndecator(),
            ),
          );
        }
        
        return Form(
          key: cubit.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Beautiful Sleek Header
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
                    child: const Icon(
                      Icons.edit_calendar_rounded,
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
                          'Add Subject Schedule',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Assign details to schedule a new class session',
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
              
              // Filter 1: College
              CustomDropDownButtonFormField(
                title: 'College',
                hintText: 'Select college',
                prefixIcon: Icons.account_balance_rounded,
                items: cubit.colleges,
                itemLabelBuilder: (e) => e.name,
                onChanged: (value) {
                  if (value != null) {
                    cubit.selectCollege(value);
                  }
                },
                value: cubit.selectedCollege,
              ),
              const SizedBox(height: 16),

              // Row 2: Program and Year Level (Side by side)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: BlocBuilder<AddSubjectScheduleCubit, AddSubjectScheduleState>(
                      buildWhen: (p, c) =>
                          c is UpdateCollegeSelection ||
                          c is UpdateProgramSelection,
                      builder: (context, state) {
                        return CustomDropDownButtonFormField(
                          title: 'Program (Section)',
                          hintText: 'Select program',
                          prefixIcon: Icons.layers_rounded,
                          items: cubit.programs,
                          itemLabelBuilder: (e) => e.name,
                          onChanged: (value) {
                            if (value != null) {
                              cubit.selectProgram(value);
                            }
                          },
                          value: cubit.selectedProgram,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: BlocBuilder<AddSubjectScheduleCubit, AddSubjectScheduleState>(
                      buildWhen: (p, c) =>
                          c is UpdateCollegeSelection ||
                          c is UpdateYearSelection,
                      builder: (context, state) {
                        return CustomDropDownButtonFormField(
                          title: 'Year Level',
                          hintText: 'Select year',
                          prefixIcon: Icons.school_rounded,
                          items: cubit.yearLevels,
                          itemLabelBuilder: (e) => 'Year $e',
                          onChanged: (value) {
                            if (value != null) {
                              cubit.selectYear(value);
                            }
                          },
                          value: cubit.selectedYearLevel,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filter 3: Subject
              BlocBuilder<AddSubjectScheduleCubit, AddSubjectScheduleState>(
                buildWhen: (p, c) =>
                    c is GetSubjectsLoading ||
                    c is GetSubjectsSuccess ||
                    c is GetSubjectsError ||
                    c is UpdateProgramSelection,
                builder: (context, state) {
                  if (state is GetSubjectsLoading) {
                    return const CustomCircularProgresIndecator();
                  }
                  return CustomDropDownButtonFormField(
                    title: 'Subject',
                    hintText: cubit.selectedProgram == null 
                      ? 'Select a program first' 
                      : 'Select subject',
                    prefixIcon: Icons.menu_book_rounded,
                    items: cubit.subjects,
                    itemLabelBuilder: (e) => e.code != null ? "${e.code} - ${e.name}" : e.name,
                    onChanged: (value) {
                      cubit.subject = value;
                    },
                    value: cubit.subject,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Row 4: Doctor and Room (Side by side)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: BlocBuilder<AddSubjectScheduleCubit, AddSubjectScheduleState>(
                      buildWhen: (p, c) =>
                          c is GetDoctorsLoading ||
                          c is GetDoctorsSuccess ||
                          c is GeDoctorsError,
                      builder: (context, state) {
                        if (state is GetDoctorsLoading) {
                          return const CustomCircularProgresIndecator();
                        }
                        return CustomDropDownButtonFormField(
                          title: 'Doctor',
                          hintText: 'Select doctor',
                          prefixIcon: Icons.person_outline_rounded,
                          items: cubit.doctors,
                          itemLabelBuilder: (e) => e.fullName,
                          onChanged: (value) {
                            cubit.doctor = value;
                          },
                          value: cubit.doctor,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: BlocBuilder<AddSubjectScheduleCubit, AddSubjectScheduleState>(
                      buildWhen: (p, c) => c is UpdateCollegeSelection,
                      builder: (context, state) {
                        return CustomDropDownButtonFormField<RoomModel>(
                          title: 'Room',
                          hintText: 'Select Room',
                          prefixIcon: Icons.meeting_room_rounded,
                          items: cubit.rooms,
                          itemLabelBuilder: (e) => e.name,
                          onChanged: (value) {
                            if (value != null) cubit.selectRoom(value);
                          },
                          value: cubit.selectedRoom,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // -- Session Type Selector --
              Text(
                'Session Type', 
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              BlocBuilder<AddSubjectScheduleCubit, AddSubjectScheduleState>(
                buildWhen: (p, c) => c is UpdateCollegeSelection, 
                builder: (context, state) {
                  return Row(
                    children: [
                      _buildTypeOption(
                        context, 
                        title: 'Lecture', 
                        isSelected: cubit.scheduleType == 'Lecture',
                        onTap: () => cubit.selectScheduleType('Lecture'),
                      ),
                      const SizedBox(width: 12),
                      _buildTypeOption(
                        context, 
                        title: 'Section', 
                        isSelected: cubit.scheduleType == 'Section',
                        onTap: () => cubit.selectScheduleType('Section'),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 20),
              const DaySelector(),
              const SizedBox(height: 20),
              const TimeSelector(),
              const SizedBox(height: 35),
              
              BlocBuilder<AddSubjectScheduleCubit, AddSubjectScheduleState>(
                buildWhen: (p, c) =>
                    c is AddSubjectScheduleLoading ||
                    p is AddSubjectScheduleLoading,
                builder: (context, state) {
                  return state is AddSubjectScheduleLoading
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
                            onPressed: cubit.addSubjectSchedule,
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text(
                              'Add Subject Schedule',
                              style: TextStyle(
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
      },
    );
  }

  Widget _buildTypeOption(BuildContext context, {required String title, required bool isSelected, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.kPrimaryColor 
                : (isDark ? const Color(0xFF1E1B15) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected 
                  ? AppColors.kPrimaryColor 
                  : (isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.3)),
            ),
            boxShadow: isSelected 
              ? [BoxShadow(color: AppColors.kPrimaryColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] 
              : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected 
                  ? Colors.white 
                  : (isDark ? Colors.white70 : Colors.black54),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
