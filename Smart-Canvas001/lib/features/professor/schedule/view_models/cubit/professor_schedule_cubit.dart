// 2. ProfessorScheduleCubit (الـ Cubit مع الفلترة والـ allSceduleSelectd)
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/features/administrator/schedule/models/subject_schedule_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:intl/intl.dart';
import 'package:smart_canvas/core/services/enhanced_notification_service.dart';

part 'professor_schedule_state.dart'; 

class ProfessorScheduleCubit extends Cubit<SchedulesState> {
  ProfessorScheduleCubit() : super(SchedulesInitial()) {
    getSchedules();
  }

  // -- variables -- //
  List<SubjectScheduleModel> subjectScheduleModels = [];
  List<SubjectScheduleModel> filteredSchedules = [];
  String _currentQuery = '';
  final supabase = getIt<SupabaseClient>();
  bool allSceduleSelectd = false;
  String selectedDay = 'Sat'; // Default start day

  // -- functions -- //
  void selectDay(String day) {
    selectedDay = day;
    emit(GetSchedulesSuccess()); // Re-emit to refresh UI with filter
  }
  getSchedules() async {
    try {
      emit(GetSchedulesLoading());
      final res = await supabase
          .from('subject_schedules')
          .select('*, subject:subjects(*), room:rooms(*)')
          .eq('admin_id', supabase.auth.currentUser!.id);

      final List schedules = res as List;
      subjectScheduleModels = schedules
          .map((e) => SubjectScheduleModel.fromJson(e))
          .toList();
      _applyFilter();

      // Schedule Notifications
      _scheduleClassNotifications(subjectScheduleModels);
      
      emit(GetSchedulesSuccess());
    } catch (e) {
      log(e.toString());
      emit(GetSchedulesFailure(message: e.toString()));
    }
  }

  void _scheduleClassNotifications(List<SubjectScheduleModel> schedules) {
    try {
      final notificationService = getIt<EnhancedNotificationService>();
      
      for (int i = 0; i < schedules.length; i++) {
        final schedule = schedules[i];
        final nextClassTime = _calculateNextClassTime(schedule.dayOfWeek, schedule.timeSlot);
        
        if (nextClassTime != null) {
          // 1. 15 minutes before
          final reminderTime = nextClassTime.subtract(const Duration(minutes: 15));
          if (reminderTime.isAfter(DateTime.now())) {
            notificationService.scheduleNotification(
              id: 3000 + i, // Professor IDs 3000+
              title: "Upcoming Lecture: ${schedule.subjectName}",
              body: "You have a lecture in 15 mins at ${schedule.room?.name ?? 'Assigned Room'}.",
              scheduledTime: reminderTime,
              type: NotificationType.schedule,
              payload: schedule.room?.name ?? 'Assigned Room',
            );
          }

          // 2. At start time
          if (nextClassTime.isAfter(DateTime.now())) {
            notificationService.scheduleNotification(
              id: 4000 + i, // Professor IDs 4000+
              title: "Lecture Starting: ${schedule.subjectName}",
              body: "Your lecture at ${schedule.room?.name ?? 'Assigned Room'} is starting now.",
              scheduledTime: nextClassTime,
              type: NotificationType.schedule,
              payload: schedule.room?.name ?? 'Assigned Room',
            );
          }
          
          log("Scheduled notifications for ${schedule.subjectName} at $reminderTime and $nextClassTime");
        }
      }
    } catch (e) {
      log("Error scheduling notifications: $e");
    }
  }

  DateTime? _calculateNextClassTime(String dayName, String timeSlot) {
    try {
      int targetWeekday = _getWeekdayIndex(dayName);
      if (targetWeekday == 0) return null;

      final parts = timeSlot.split('-');
      if (parts.isEmpty) return null;
      final startTimeString = parts[0].trim();

      final now = DateTime.now();
      final format = DateFormat("hh:mm a"); 
      final timeDate = format.parse(startTimeString);
      
      var targetDate = DateTime(now.year, now.month, now.day, timeDate.hour, timeDate.minute);
      
      while (targetDate.weekday != targetWeekday) {
        targetDate = targetDate.add(const Duration(days: 1));
      }
      
      if (targetDate.isBefore(now)) {
        targetDate = targetDate.add(const Duration(days: 7));
      }

      return targetDate;
    } catch (e) {
      log("Error parsing prediction time: $e");
      return null;
    }
  }

  int _getWeekdayIndex(String day) {
     switch (day.toLowerCase().trim()) {
       case 'monday': return DateTime.monday;
       case 'tuesday': return DateTime.tuesday;
       case 'wednesday': return DateTime.wednesday;
       case 'thursday': return DateTime.thursday;
       case 'friday': return DateTime.friday;
       case 'saturday': return DateTime.saturday;
       case 'sunday': return DateTime.sunday;
       default: return 0;
     }
  }

  void _applyFilter() {
    List<SubjectScheduleModel> baseList = subjectScheduleModels;
    if (!allSceduleSelectd) {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        baseList = subjectScheduleModels
            .where((e) => e.adminId == currentUserId)
            .toList();
      }
    }

    if (_currentQuery.trim().isEmpty) {
      filteredSchedules = baseList;
      return;
    }

    final q = _currentQuery.trim().toLowerCase();
    filteredSchedules = baseList.where((schedule) {
      final subjectMatch = schedule.subjectName.toLowerCase().contains(q);
      final codeMatch = (schedule.subject?.code ?? '').toLowerCase().contains(q);
      final roomMatch = (schedule.room?.name ?? '').toLowerCase().contains(q);
      final dayMatch = schedule.dayOfWeek.toLowerCase().contains(q) || schedule.formattedDay.toLowerCase().contains(q);
      final timeMatch = schedule.timeSlot.toLowerCase().contains(q);
      return subjectMatch || codeMatch || roomMatch || dayMatch || timeMatch;
    }).toList();
  }

  filterSchedules({required bool allCourses}) {
    allSceduleSelectd = allCourses;
    _applyFilter();
    emit(GetSchedulesSuccess());
  }

  void searchSchedules(String query) {
    _currentQuery = query;
    _applyFilter();
    emit(GetSchedulesSuccess());
  }
}