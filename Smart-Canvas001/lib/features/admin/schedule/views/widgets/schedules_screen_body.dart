import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:smart_canvas/features/administrator/schedule/models/subject_schedule_model.dart';
import 'package:smart_canvas/features/admin/schedule/view_models/cubit/schedules_cubit.dart';
import 'package:smart_canvas/features/admin/schedule/views/widgets/doctor_schedules_header.dart';

class DoctorSchedulesScreenBody extends StatelessWidget {
  const DoctorSchedulesScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DoctorSchedulesCubit(),
      child: Column(
        children: [
          const DoctorSchedulesHeader(),
          SizedBox(height: SizeConfig.height * 0.02),
          const Expanded(child: _ScheduleTable()),
        ],
      ),
    );
  }
}

class _ScheduleCell extends StatelessWidget {
  final String title;
  final Color? color;

  const _ScheduleCell({required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    final isEmpty = title == '—';

    return Container(
      width: 170,
      height: 80,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isEmpty ? Colors.grey.shade300 : color!.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isEmpty ? Colors.grey : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _DayHeaderCell extends StatelessWidget {
  final String text;
  const _DayHeaderCell({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      height: 80,
      alignment: Alignment.center,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppTextStyles.title16BlackW500,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _TimeHeaderCell extends StatelessWidget {
  final String text;
  const _TimeHeaderCell({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      height: 80,
      alignment: Alignment.center,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppTextStyles.title16BlackW500,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final String day;
  final Map<String, String> scheduleForDay; // timeSlot -> subject for this day
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
          final subject = scheduleForDay[time] ?? '—';
          final color = subject == '—' ? null : subjectColors[subject];
          return _ScheduleCell(title: subject, color: color);
        }),
      ],
    );
  }
}

class _ScheduleTable extends StatelessWidget {
  const _ScheduleTable();

  static const List<String> days = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu'];
  static const List<String> timeSlots = [
    "08:00 AM - 10:00 AM",
    "10:00 AM - 12:00 PM",
    "12:00 PM - 02:00 PM",
    "02:00 PM - 04:00 PM",
    "04:00 PM - 06:00 PM",
  ];

  // دالة مساعدة لتحديد لون المادة ديناميكياً (بناءً على هاش للمادة)
  // توسيع القائمة لألوان أكثر تنوعاً وجاذبية، عشان كل مادة تاخد لون مختلف وثابت
  Color _getSubjectColor(String subjectName) {
    final hash = subjectName.hashCode;
    final colors = [
      Colors.blue.shade600, // أزرق أساسي
      Colors.green.shade600, // أخضر أساسي
      Colors.orange.shade600, // برتقالي أساسي
      Colors.purple.shade600, // بنفسجي أساسي
      Colors.red.shade600, // أحمر أساسي
      Colors.teal.shade600, // فيروزي أساسي
      Colors.indigo.shade600, // إنديغو أساسي
      Colors.pink.shade600, // وردي أساسي
      Colors.cyan.shade600, // سماوي أساسي
      Colors.amber.shade600, // عسلي أساسي
      Colors.deepPurple.shade600, // بنفسجي غامق
      Colors.lime.shade600, // أخضر ليموني
      Colors.brown.shade600, // بني أساسي
      Colors.grey.shade700, // رمادي غامق
      Colors.lightGreen.shade600, // أخضر فاتح
      Colors.yellow.shade700, // أصفر غامق
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
    return BlocBuilder<DoctorSchedulesCubit, SchedulesState>(
      builder: (context, state) {
        if (state is GetSchedulesLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is GetSchedulesFailure) {
          return Center(child: Text('Error: ${state.message}'));
        } else if (state is GetSchedulesSuccess) {
          final cubit = context.read<DoctorSchedulesCubit>();
          final subjectColors = _getSubjectColors(cubit.filteredSchedules);

          // إنشاء خريطة للجدول: day -> {timeSlot -> subject}
          // الـ timeSlot دلوقتي field مباشر من الـ model
          final Map<String, Map<String, String>> scheduleMap = {};
          for (var model in cubit.filteredSchedules) {
            final day = model.formattedDay; // 'Sat' بدلاً من 'Saturday'
            final time = model.timeSlot; // الـ slot المختار مباشرة
            final subject = model.subjectName; // 'Human Anatomy I' أو '—'

            if (!scheduleMap.containsKey(day)) {
              scheduleMap[day] = {};
            }
            scheduleMap[day]![time] = subject;
          }

          // بناء الجدول: صف علوي للـ headers (Day + Times)، ثم صفوف لكل day
          return RefreshIndicator(
            onRefresh: () async {
              await cubit.getSchedules();
            },
            color: Colors.white,
            backgroundColor: AppColors.kPrimaryColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الصف العلوي: headers للأوقات
                    Row(
                      children: [
                        const _DayHeaderCell(text: 'Day'), // عمود اليوم
                        ...timeSlots.map(
                          (time) => _TimeHeaderCell(
                            text: time.replaceAll(" - ", "\n"),
                          ),
                        ),
                      ],
                    ),
                    // الصفوف لكل day
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
          );
        }
        return const SizedBox(); // حالة افتراضية
      },
    );
  }
}
