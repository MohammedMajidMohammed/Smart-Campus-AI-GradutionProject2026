import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/map_utils.dart';
import 'package:smart_canvas/features/student/schedule/view_models/cubit/student_schedule_cubit.dart';
import 'package:smart_canvas/features/administrator/schedule/models/subject_schedule_model.dart';
import 'package:smart_canvas/features/professor/schedule/views/widgets/room_location_dialog.dart';

class StudentScheduleScreenBody extends StatefulWidget {
  const StudentScheduleScreenBody({super.key});

  @override
  State<StudentScheduleScreenBody> createState() => _StudentScheduleScreenBodyState();
}

class _StudentScheduleScreenBodyState extends State<StudentScheduleScreenBody> {
  bool _isTableView = false;

  @override
  Widget build(BuildContext context) {
    // Media Query Logic for Responsiveness
    final isTablet = MediaQuery.of(context).size.width > 600;
    final horizontalPadding = SizeConfig.width * 0.04;

    return BlocProvider(
      create: (_) => StudentScheduleCubit(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text("my_schedule".tr()),
          centerTitle: true,
          backgroundColor: AppColors.kPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            // View Toggle Button
             IconButton(
              onPressed: () {
                setState(() {
                  _isTableView = !_isTableView;
                });
              },
              icon: Icon(
                _isTableView ? Icons.view_day_outlined : Icons.table_chart_outlined,
                color: Colors.white,
              ),
              tooltip: _isTableView ? "switch_timeline".tr() : "switch_table".tr(),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocBuilder<StudentScheduleCubit, StudentScheduleState>(
          builder: (context, state) {
            if (state is StudentScheduleLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is StudentScheduleError) {
              return Center(child: Text('Error: ${state.message}'));
            }

            final cubit = context.read<StudentScheduleCubit>();
            
            // For Table View: Show ALL filtered schedules
            // For Timeline View: Filter by selected Day
            
            if (_isTableView) {
              return _GridScheduleView(
                schedules: cubit.filterSchedule,
                isTablet: isTablet,
              );
            }

            // --- Timeline View Logic ---
            return Column(
              children: [
                SizedBox(height: SizeConfig.height * 0.02),
                // Day Selector
                Container(
                  height: 50,
                  margin: EdgeInsets.symmetric(vertical: SizeConfig.height * 0.02),
                  child: BlocBuilder<StudentScheduleCubit, StudentScheduleState>(
                    builder: (context, state) {
                       // cubit defined above
                      final days = [
                        'sat_short'.tr(),
                        'sun_short'.tr(),
                        'mon_short'.tr(),
                        'tue_short'.tr(),
                        'wed_short'.tr(),
                        'thu_short'.tr(),
                        'fri_short'.tr()
                      ];
                      return ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        scrollDirection: Axis.horizontal,
                        itemCount: days.length,
                        separatorBuilder: (context, index) => SizedBox(width: SizeConfig.width * 0.02),
                        itemBuilder: (context, index) {
                          final day = days[index];
                          final isSelected = cubit.selectedDay == day;
                          return GestureDetector(
                            onTap: () => cubit.selectDay(day),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.kPrimaryColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(30), // Pill shape
                                border: isSelected ? null : Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                day,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey.shade600,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: isTablet ? 16 : 14,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                
                SizedBox(height: SizeConfig.height * 0.02),
                
                // Timeline List
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final selectedDay = cubit.selectedDay;
                      
                      // Filter and Sort schedules
                      final daySchedules = cubit.filterSchedule.where((s) {
                        return s.formattedDay == selectedDay;
                      }).toList();

                      // Sort by start time (parsing "09:00 AM - ...")
                      daySchedules.sort((a, b) {
                        try {
                          final t1 = _parseStartTime(a.timeSlot);
                          final t2 = _parseStartTime(b.timeSlot);
                          return t1.compareTo(t2);
                        } catch (e) {
                          return 0; 
                        }
                      });

                      if (daySchedules.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(FontAwesomeIcons.calendarXmark, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                "no_classes_today".tr(),
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10),
                        itemCount: daySchedules.length,
                        itemBuilder: (context, index) {
                          final schedule = daySchedules[index];
                          return _TimelineCard(
                            model: schedule,
                            isLast: index == daySchedules.length - 1,
                            isTablet: isTablet,
                          );
                        },
                      );
                    }
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Helper to parse "09:00 AM" to minutes for sorting
  int _parseStartTime(String timeSlot) {
    try {
      // timeSlot format: "09:00 AM - ..."
      final parts = timeSlot.split(" - ");
      if (parts.isEmpty) return 0;
      final timePart = parts[0].trim(); // "09:00 AM"
      
      // Parse HH:MM AM/PM
      final spaces = timePart.split(" ");
      if (spaces.length != 2) return 0;
      
      final time = spaces[0].split(":");
      final period = spaces[1];
      
      int hour = int.parse(time[0]);
      int minute = int.parse(time[1]);
      
      if (period == "PM" && hour != 12) hour += 12;
      if (period == "AM" && hour == 12) hour = 0;
      
      return hour * 60 + minute;
    } catch (e) {
      return 0;
    }
  }
}

class _GridScheduleView extends StatelessWidget {
  final List<SubjectScheduleModel> schedules;
  final bool isTablet;

  const _GridScheduleView({required this.schedules, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return Center(child: Text("no_schedules".tr()));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Identify all unique Time Slots
    final Set<String> timeSlotsSet = {};
    for (var s in schedules) {
      timeSlotsSet.add(s.timeSlot);
    }
    
    // 2. Sort Time Slots Chronologically
    final List<String> sortedTimeSlots = timeSlotsSet.toList();
    sortedTimeSlots.sort((a, b) {
      final t1 = _parseStartTime(a);
      final t2 = _parseStartTime(b);
      return t1.compareTo(t2);
    });

    // 3. Define Days
    final days = [
      'sat_short'.tr(),
      'sun_short'.tr(),
      'mon_short'.tr(),
      'tue_short'.tr(),
      'wed_short'.tr(),
      'thu_short'.tr()
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            // --- Header Row (Time Slots) ---
            Row(
              children: [
                // Top-Left Corner (Day Label)
                Container(
                  width: 90,
                  height: 60,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(right: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.kPrimaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white12 : AppColors.kPrimaryColor.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    "day_lbl".tr(), 
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : AppColors.kPrimaryColor,
                      fontSize: 13,
                    ),
                  ),
                ),
                
                // Time Slot Columns
                ...sortedTimeSlots.map((slot) {
                  return Container(
                    width: 160,
                    height: 60,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(right: 8, bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                      boxShadow: [
                        if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
                      ],
                    ),
                    child: Text(
                      slot.replaceAll(" - ", "\n"),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey.shade800,
                      ),
                    ),
                  );
                }),
              ],
            ),

            // --- Data Rows (Days) ---
            ...days.map((day) {
              return Row(
                children: [
                  // Day Header (Left Column)
                  Container(
                    width: 90,
                    height: 100, // Fixed height for grid cells
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(right: 8, bottom: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                      boxShadow: [
                        if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.kPrimaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            day, 
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.grey.shade800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Schedule Cells for this Day
                  ...sortedTimeSlots.map((timeSlot) {
                    // Find schedule for this Day + Time
                    final matchingSchedules = schedules.where(
                      (s) => s.formattedDay == day && s.timeSlot == timeSlot
                    ).toList();

                    if (matchingSchedules.isNotEmpty) {
                      final schedule = matchingSchedules.first; // Assume one class per slot per day
                      final colors = _getSubjectColor(schedule.subjectName, isDark);
                      final bgColor = colors['bg']!;
                      final textColor = colors['text']!;
                      
                      return GestureDetector(
                        onTap: () {
                          if (schedule.room != null) {
                             showDialog(
                              context: context,
                              builder: (_) => RoomLocationDialog(room: schedule.room!),
                            );
                          }
                        },
                        onLongPress: () {
                          if (schedule.room?.mapX != null && schedule.room?.mapY != null) {
                            MapUtils.openMap(schedule.room!.mapX!, schedule.room!.mapY!);
                          }
                        },
                        child: Container(
                          width: 160,
                          height: 100,
                          margin: const EdgeInsets.only(right: 8, bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: textColor.withValues(alpha: 0.2), width: 1.5),
                            boxShadow: [
                              BoxShadow(color: bgColor.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 3))
                            ]
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                schedule.subjectName,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.5,
                                  height: 1.2,
                                ),
                              ),
                              if (schedule.room != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: textColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6)
                                  ),
                                  child: Text(
                                    schedule.room!.name,
                                    style: TextStyle(
                                      color: textColor, 
                                      fontSize: 10.5, 
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              ]
                            ],
                          ),
                        ),
                      );
                    } else {
                      // Empty Slot
                      return Container(
                        width: 160,
                        height: 100,
                        margin: const EdgeInsets.only(right: 8, bottom: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.01) : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: const SizedBox(),
                      );
                    }
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // Helper to parse time for sorting (duplicated to be self-contained within this widget if needed)
  int _parseStartTime(String timeSlot) {
    try {
      final parts = timeSlot.split(" - ");
      if (parts.isEmpty) return 0;
      final timePart = parts[0].trim();
      final spaces = timePart.split(" ");
      if (spaces.length != 2) return 0;
      final time = spaces[0].split(":");
      final period = spaces[1];
      int hour = int.parse(time[0]);
      int minute = int.parse(time[1]);
      if (period == "PM" && hour != 12) hour += 12;
      if (period == "AM" && hour == 12) hour = 0;
      return hour * 60 + minute;
    } catch (e) {
      return 0;
    }
  }
}

class _TimelineCard extends StatelessWidget {
  final SubjectScheduleModel model;
  final bool isLast;
  final bool isTablet;

  const _TimelineCard({
    required this.model,
    required this.isLast,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _getSubjectColor(model.subjectName, isDark);
    final bgColor = colors['bg']!;
    final textColor = colors['text']!;

    // Parsing Time for Display
    final times = model.timeSlot.split(" - ");
    final startTime = times.isNotEmpty ? times[0] : "";
    final endTime = times.length > 1 ? times[1] : "";

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Timeline Column
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Text(
                  startTime.replaceAll(" ", "\n"),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.2
                  ),
                ),
                const SizedBox(height: 8),
                // Dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: textColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? const Color(0xFF0F0E0A) : Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: textColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 2,
                      )
                    ]
                  ),
                ),
                // Line
                Expanded(
                  child: isLast ? const SizedBox() : Container(
                    width: 2,
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 2. Card Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: GestureDetector(
                onTap: () {
                   if (model.room != null) {
                    showDialog(
                      context: context,
                      builder: (_) => RoomLocationDialog(room: model.room!),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : textColor.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.grey.shade100,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Strip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(14),
                            topRight: Radius.circular(14),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_filled_rounded, size: 14, color: textColor),
                            const SizedBox(width: 6),
                            Text(
                              "$startTime - $endTime",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Body
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              model.subjectName,
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // Room Chip
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: textColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.location_on_rounded, size: 14, color: textColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        model.room?.name ?? "no_room".tr(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, Color> _getSubjectColor(String subject, bool isDark) {
  if (isDark) {
    final colors = [
      {'bg': const Color(0xFF1B3B2B), 'text': const Color(0xFF8CD3A5)}, // Sage / University Green
      {'bg': const Color(0xFF45300B), 'text': const Color(0xFFFCD34D)}, // Gold
      {'bg': const Color(0xFF1E1B4B), 'text': const Color(0xFFC7D2FE)}, // Indigo
      {'bg': const Color(0xFF115E59), 'text': const Color(0xFF99F6E4)}, // Teal
      {'bg': const Color(0xFF3B0764), 'text': const Color(0xFFE9D5FF)}, // Lavender
      {'bg': const Color(0xFF4C0519), 'text': const Color(0xFFFECDD3)}, // Rose
      {'bg': const Color(0xFF0369A1).withValues(alpha: 0.3), 'text': const Color(0xFFBAE6FD)}, // Sky Blue
    ];
    return colors[subject.hashCode.abs() % colors.length];
  } else {
    final colors = [
      {'bg': const Color(0xFFE2F0D9), 'text': const Color(0xFF1E8449)}, // Sage / University Green
      {'bg': const Color(0xFFFEF3C7), 'text': const Color(0xFFB45309)}, // Amber / University Gold
      {'bg': const Color(0xFFE0E7FF), 'text': const Color(0xFF4338CA)}, // Indigo
      {'bg': const Color(0xFFE0F2F1), 'text': const Color(0xFF00695C)}, // Teal
      {'bg': const Color(0xFFF3E8FF), 'text': const Color(0xFF6B21A8)}, // Lavender
      {'bg': const Color(0xFFFFE4E6), 'text': const Color(0xFF9F1239)}, // Rose
      {'bg': const Color(0xFFE0F2FE), 'text': const Color(0xFF0369A1)}, // Sky Blue
    ];
    return colors[subject.hashCode.abs() % colors.length];
  }
}
