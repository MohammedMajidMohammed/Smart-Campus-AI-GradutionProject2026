import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/administrator/schedule/models/subject_schedule_model.dart';
import 'package:smart_canvas/features/administrator/schedule/view_models/cubit/schedules_cubit.dart';
import 'package:smart_canvas/features/administrator/schedule/views/widgets/administrator_subject_schedule_header.dart';
import 'package:smart_canvas/features/administrator/schedule/view_models/cubit/add_subject_schedule_cubit.dart';
import 'package:smart_canvas/features/administrator/schedule/views/widgets/add_subject_schedule_bottom_sheet_body.dart';

class SchedulesScreenBody extends StatelessWidget {
  const SchedulesScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFFAF9F5),
      child: const Column(
        children: [
          AdministratorSubjectScheduleHeader(),
          SizedBox(height: 12),
          Expanded(child: _ScheduleTable()),
        ],
      ),
    );
  }
}

class _ScheduleCell extends StatelessWidget {
  final SubjectScheduleModel? model;
  final Color? color;
  final VoidCallback? onTap;

  const _ScheduleCell({this.model, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = model?.subjectName ?? '';
    final isEmpty = title.isEmpty || title == '—';

    return GestureDetector(
      onTap: !isEmpty ? onTap : null,
      child: Container(
        width: 175,
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: isEmpty
              ? (isDark ? const Color(0xFF1E1B15).withValues(alpha: 0.3) : const Color(0xFFFAF9F5))
              : color!.withValues(alpha: isDark ? 0.22 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEmpty
                ? (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100)
                : color!.withValues(alpha: isDark ? 0.35 : 0.15),
            width: 1,
          ),
          boxShadow: isEmpty
              ? []
              : [
                  BoxShadow(
                    color: color!.withValues(alpha: isDark ? 0.08 : 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              if (!isEmpty)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    color: color,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 10, top: 10, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isEmpty ? '' : title,
                        style: TextStyle(
                          color: _getContrastColor(color ?? Colors.grey, isDark),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (model?.room != null)
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    color: _getContrastColor(color!, isDark).withValues(alpha: 0.7),
                                    size: 11,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      model!.room!.name,
                                      style: TextStyle(
                                        color: _getContrastColor(color!, isDark).withValues(alpha: 0.85),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (model?.yearLevel != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: color!.withValues(alpha: isDark ? 0.3 : 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "Y${model!.yearLevel}",
                                style: TextStyle(
                                  color: _getContrastColor(color!, isDark),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
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
    );
  }

  Color _getContrastColor(Color color, bool isDark) {
    if (isDark) return Colors.white.withValues(alpha: 0.95);
    return Color.fromARGB(
      255,
      ((color.r * 255.0) * 0.70).round().clamp(0, 255),
      ((color.g * 255.0) * 0.70).round().clamp(0, 255),
      ((color.b * 255.0) * 0.70).round().clamp(0, 255),
    );
  }
}

class _DayHeaderCell extends StatelessWidget {
  final String text;
  const _DayHeaderCell({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCorner = text == 'Day';

    return Container(
      width: 120,
      height: 80,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isCorner 
            ? (isDark ? const Color(0xFF1E1B15) : const Color(0xFFE2E8F0))
            : (isDark ? const Color(0xFF1E1B15) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
          width: 1,
        ),
        boxShadow: isCorner 
            ? [] 
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.05 : 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Stack(
        children: [
          if (!isCorner)
            Positioned(
              left: 0,
              top: 18,
              bottom: 18,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF10B981) : AppColors.kPrimaryColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(2),
                    bottomRight: Radius.circular(2),
                  ),
                ),
              ),
            ),
          Center(
            child: Text(
              text,
              style: TextStyle(
                color: isCorner
                    ? (isDark ? Colors.white70 : const Color(0xFF2A2720))
                    : (isDark ? Colors.white : AppColors.kPrimaryColor),
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeHeaderCell extends StatelessWidget {
  final String text;
  const _TimeHeaderCell({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 175,
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 14,
            color: isDark ? Colors.white60 : Colors.grey.shade600,
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF475569),
              fontWeight: FontWeight.w700,
              fontSize: 11,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final String day;
  final Map<String, SubjectScheduleModel> scheduleForDay; 
  final Map<String, Color> subjectColors;

  const _DayRow({
    required this.day,
    required this.scheduleForDay,
    required this.subjectColors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DayHeaderCell(text: day),
        ..._ScheduleTable.timeSlots.map((time) {
          final model = scheduleForDay[time];
          final subject = model?.subjectName ?? '—';
          final color = subject == '—' ? null : subjectColors[subject];
          return _ScheduleCell(
            model: model, 
            color: color,
            onTap: () {
              if (model != null) {
                _showActions(context, model);
              }
            },
          );
        }),
      ],
    );
  }

  void _showActions(BuildContext context, SubjectScheduleModel model) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1B15) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.class_rounded,
                        color: AppColors.kPrimaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model.subjectName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Room: ${model.room?.name ?? '—'} • ${model.formattedDay} • ${model.timeSlot}",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E8449).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_rounded, color: Color(0xFF1E8449)),
                ),
                title: Text(
                  'Edit Class Schedule',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: const Text('Change time, day, room, or details'),
                onTap: () async {
                  Navigator.pop(context);
                  await showModalBottomSheet(
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    context: context,
                    builder: (context) => BlocProvider(
                      create: (context) => AddSubjectScheduleCubit(editModel: model),
                      child: const AddSubjectScheduleModalBottomSheetBody(),
                    ),
                  );
                  // Refresh after edit
                  if (context.mounted) {
                    context.read<SchedulesCubit>().getSchedules();
                  }
                },
              ),
              
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                ),
                title: const Text(
                  'Delete Class Schedule',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                subtitle: const Text('Permanently remove this schedule slot'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, model);
                },
              ),
              
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SubjectScheduleModel model) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1B15) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Class?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Are you sure you want to permanently delete the schedule for ${model.subjectName}?',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(diagContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(diagContext);
              context.read<SchedulesCubit>().deleteSchedule(model.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ScheduleTable extends StatelessWidget {
  const _ScheduleTable();

  static const List<String> days = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu'];
  static const List<String> timeSlots = [
    "09:00 AM - 11:00 AM",
    "11:00 AM - 01:00 PM",
    "01:00 PM - 03:00 PM",
    "03:00 PM - 05:00 PM",
    "05:00 PM - 07:00 PM",
  ];

  Color _getSubjectColor(String subjectName) {
    final hash = subjectName.hashCode;
    final colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.red.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade600,
      Colors.pink.shade600,
      Colors.cyan.shade600,
      Colors.amber.shade600,
      Colors.deepPurple.shade600,
      Colors.lime.shade600,
      Colors.brown.shade600,
      Colors.grey.shade700,
      Colors.lightGreen.shade600,
      Colors.yellow.shade700,
    ];
    return colors[(hash.abs() % colors.length)];
  }

  Map<String, Color> _getSubjectColors(List<SubjectScheduleModel> schedules) {
    final Map<String, Color> colors = {};
    for (var model in schedules) {
      final subject = model.subjectName;
      if (subject != '—' && !colors.containsKey(subject)) {
        colors[subject] = _getSubjectColor(subject);
      }
    }
    return colors;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SchedulesCubit, SchedulesState>(
      builder: (context, state) {
        final cubit = context.read<SchedulesCubit>();
        if (state is GetSchedulesLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is GetSchedulesFailure) {
          return Center(child: Text('Error: ${state.message}'));
        } else if (state is GetSchedulesSuccess) {
          final subjectColors = _getSubjectColors(cubit.filteredSchedules);

          final Map<String, Map<String, SubjectScheduleModel>> scheduleMap = {};
          for (var model in cubit.filteredSchedules) {
            final day = model.formattedDay;
            final time = model.timeSlot;

            if (!scheduleMap.containsKey(day)) {
              scheduleMap[day] = {};
            }
            scheduleMap[day]![time] = model;
          }

          return RefreshIndicator(
            onRefresh: () async {
              await cubit.getSchedules();
            },
            color: Colors.white,
            backgroundColor: AppColors.kPrimaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const _DayHeaderCell(text: 'Day'),
                          ...timeSlots.map(
                            (time) => _TimeHeaderCell(
                              text: time.replaceAll(" - ", "\n"),
                            ),
                          ),
                        ],
                      ),
                      ...days.map((day) {
                        final dayData = scheduleMap[day] ?? {};
                        return _DayRow(
                          day: day,
                          scheduleForDay: dayData,
                          subjectColors: subjectColors,
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}
