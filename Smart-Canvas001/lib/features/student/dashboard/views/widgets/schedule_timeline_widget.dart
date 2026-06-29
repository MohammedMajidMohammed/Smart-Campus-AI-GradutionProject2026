import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/services/notification_service.dart';
import 'package:smart_canvas/core/utilies/theme/app_theme.dart';
import 'package:smart_canvas/features/administrator/schedule/models/subject_schedule_model.dart';
import 'package:smart_canvas/features/student/schedule/view_models/cubit/student_schedule_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';

class ScheduleTimelineWidget extends StatefulWidget {
  const ScheduleTimelineWidget({super.key});

  @override
  State<ScheduleTimelineWidget> createState() => _ScheduleTimelineWidgetState();
}

class _ScheduleTimelineWidgetState extends State<ScheduleTimelineWidget> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  // Helper to parse "09:00 AM" to today's DateTime
  DateTime? _parseTime(String timeSlot) {
    try {
      final startTimeString = timeSlot.split(' - ')[0]; // "08:00 AM"
      final format = DateFormat("hh:mm a"); // 12-hour format
      final time = format.parse(startTimeString);
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, time.hour, time.minute);
    } catch (e) {
      return null;
    }
  }

  // Calculate time remaining
  String _getTimeRemaining(DateTime classTime) {
    final diff = classTime.difference(_now);
    if (diff.isNegative) return "started_lbl".tr();
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
      if (hours > 0) return "$hours ${'hr_lbl'.tr()} $minutes ${'min_left'.tr()}";
      return "$minutes ${'min_left'.tr()}";
  }

  void _scheduleNotificationIfNeeded(SubjectScheduleModel schedule) {
    // Basic logic: If today and hasn't passed, schedule notification 15 mins before
    // This is better done in the Cubit or a Service to avoid duplicate scheduling every rebuild
    // For now, we assume the user just opened the app.
    final classTime = _parseTime(schedule.timeSlot);
    if (classTime == null) return;
    
    final notificationTime = classTime.subtract(const Duration(minutes: 15));
    if (notificationTime.isAfter(DateTime.now())) {
      getIt<NotificationService>().scheduleNotification(
        id: schedule.hashCode, 
        title: "${'upcoming_class'.tr()}: ${schedule.subjectName}", 
        body: "${'starts_in_15'.tr()} ${schedule.timeSlot}", 
        scheduledTime: notificationTime
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StudentScheduleCubit(),
      child: BlocBuilder<StudentScheduleCubit, StudentScheduleState>(
        builder: (context, state) {
          if (state is StudentScheduleLoaded) {
            final cubit = BlocProvider.of<StudentScheduleCubit>(context);
            // Filter Today's Schedule
            final today = DateFormat('EEEE').format(_now); // e.g., "Monday"
            final todaySchedule = cubit.scheduleList.where((element) => element.dayOfWeek == today).toList();
            
            // Sort by time
             todaySchedule.sort((a, b) {
               final t1 = _parseTime(a.timeSlot);
               final t2 = _parseTime(b.timeSlot);
               if (t1 == null || t2 == null) return 0;
               return t1.compareTo(t2);
             });

             // Schedule Notifications
             for (var element in todaySchedule) {
               _scheduleNotificationIfNeeded(element);
             }

            if (todaySchedule.isEmpty) {
              return const _EmptySchedule();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text(
                        "todays_schedule".tr(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                      ),
                      Text(
                        DateFormat('MMM d, yyyy').format(_now),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...todaySchedule.map((schedule) {
                   final classTime = _parseTime(schedule.timeSlot);
                   final isActive = classTime != null && 
                                    classTime.isBefore(_now.add(const Duration(minutes: 0))) && 
                                    classTime.add(const Duration(hours: 2)).isAfter(_now); // Assuming 2hr duration
                   
                   return _buildScheduleItem(context, schedule, isActive: isActive, classTime: classTime);
                }),
              ],
            );
          } else if (state is StudentScheduleError) {
            return Center(child: Text("Error: ${state.message}"));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildScheduleItem(BuildContext context, SubjectScheduleModel schedule, {bool isActive = false, DateTime? classTime}) {
    String timeLeft = "";
    if (classTime != null && !isActive && classTime.isAfter(_now)) {
      timeLeft = _getTimeRemaining(classTime);
    }
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // We use a container that looks like DashboardCard but maybe slightly different for 'active' state
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: isActive 
              ? AppTheme.primaryColor.withValues(alpha: 0.1) 
              : (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive 
                ? AppTheme.primaryColor.withValues(alpha: 0.5) 
                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ] : [
             BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                schedule.timeSlot.split(' ')[0], 
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              Text(
                schedule.timeSlot.split(' ')[1], 
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
            ],
          ),
          title: Text(schedule.subjectName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              // Location placeholder (if model has it, use it)
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: Theme.of(context).disabledColor),
                  const SizedBox(width: 4),
                  Text("Hall 3", style: Theme.of(context).textTheme.bodySmall), // Placeholder
                ],
              ),
              if (timeLeft.isNotEmpty) 
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "${'starts_in'.tr()} $timeLeft",
                    style: const TextStyle(color: AppTheme.warning, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          trailing: isActive 
              ? Chip(
                  label: Text("now_badge".tr(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  backgroundColor: AppTheme.primaryColor,
                  padding: EdgeInsets.zero,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ) 
              : null,
        ),
      ),
    );
  }
}

class _EmptySchedule extends StatelessWidget {
  const _EmptySchedule();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            offset: const Offset(0, 10),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.kPrimaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_rounded,
              size: 42,
              color: AppColors.kPrimaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "no_classes_today".tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF1E1B15),
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "enjoy_your_rest_day".tr(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
