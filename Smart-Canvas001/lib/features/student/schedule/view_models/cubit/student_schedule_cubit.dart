import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/services/hive_service.dart';
import 'package:smart_canvas/features/administrator/schedule/models/subject_schedule_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_canvas/core/services/enhanced_notification_service.dart';
import 'package:smart_canvas/features/auth/sign_in/models/user_model.dart' as auth;
import 'package:intl/intl.dart';

part 'student_schedule_state.dart';

class StudentScheduleCubit extends Cubit<StudentScheduleState> {
  StudentScheduleCubit() : super(StudentScheduleLoading()){
    getStudentSchedule();
  }
  //-- variables --//
  List<SubjectScheduleModel> scheduleList = [];
  List<SubjectScheduleModel> filterSchedule = [];
  String _currentQuery = '';
  final supabase = getIt<SupabaseClient>();
  String selectedDay = 'Sat'; // Default start day

  //-- functions --//
  void selectDay(String day) {
    selectedDay = day;
    emit(StudentScheduleLoaded()); // Re-emit to refresh UI
  }

  getStudentSchedule() async {
    final hiveService = getIt<HiveService>(); // Get Hive Instance

    try {
      // 1. Try Fetching from API
      final authUser = supabase.auth.currentUser;
      if (authUser == null) {
        emit(StudentScheduleError(message: "Not logged in"));
        return;
      }

      // Re-fetch user data directly to ensure we have fresh IDs (bypasses stale CacheHelper)
      final userRes = await supabase.rpc('get_user_with_role', params: {'p_user_id': authUser.id});
      if (userRes != null && (userRes as List).isNotEmpty) {
        final freshUser = auth.UserModel.fromJson(userRes.first);
        // Sync cache while we are at it
        await getIt<CacheHelper>().saveUserModel(freshUser);
        log("Fresh user data fetched for schedule: ${freshUser.collegeId}, ${freshUser.academicYearId}");
      }

      final auth.UserModel? user = getIt<CacheHelper>().getUserModel();
      log("FETCHING SCHEDULE FOR STUDENT:");
      log(" - User ID: ${user?.id}");
      log(" - College ID: ${user?.collegeId}");
      log(" - Program ID: ${user?.academicYearId}");
      log(" - Year Level: ${user?.yearLevel}");
      
      if (user?.collegeId == null || user?.academicYearId == null) {
        log("CRITICAL: Student profile is incomplete in CacheHelper.");
        emit(StudentScheduleError(message: "Please complete your profile (College & Program) in Settings to see your schedule."));
        return;
      }

      var response = await supabase.rpc(
        'get_my_student_schedule_full',
        params: {
          'p_college_id': user?.collegeId ?? '',
          'p_program_id': user?.academicYearId ?? '',
          'p_year_level': user?.yearLevel ?? 1,
        },
      );
      
      log("Schedule RPC Response received: ${response is List ? response.length : 'error'} items");
      
      List list = (response as List?) ?? [];
      
      // DIAGNOSTIC FALLBACK: If empty, try without program_id filter to see if IDs are mismatched
      if (list.isEmpty) {
        log("Diagnostic: Strict query empty. Trying broader query (College + Year)...");
        final broaderResponse = await supabase
            .from('subject_schedules')
            .select('*, subject:subjects!inner(*), room:rooms(*)')
            .eq('year_level', user!.yearLevel ?? 1)
            .eq('subject.college_id', user.collegeId ?? '');
        
        if (broaderResponse.isNotEmpty) {
          log("Diagnostic: Found ${broaderResponse.length} items with College+Year but NOT with Program. ID mismatch suspected.");
          emit(StudentScheduleError(
            message: "Program mismatch (IDs in DB don't match your profile).\n"
                     "Your Program ID: ${user.academicYearId}\n"
                     "Please re-select your Program in Profile Settings."
          ));
          return;
        } else {
          log("Diagnostic: Table is empty for College ${user.collegeId} and Year ${user.yearLevel}");
          // If even broader query is empty, maybe nothing is seeded for this college?
          emit(StudentScheduleError(
            message: "No schedules found in database for College: ${user.collegeId.toString().substring(0, 8)}... (Year ${user.yearLevel})."
          ));
          return;
        }
      }

      // Note: RPC returns List<Map<String, dynamic>> where each map has 'json_data' key
      scheduleList = list.map((e) {
        final data = e['json_data'] as Map<String, dynamic>? ?? {};
        return SubjectScheduleModel.fromJson(data);
      }).toList(); 
      
      _applyFilter();
      log("Mapped ${scheduleList.length} subjects to scheduleList");

      // 2. Cache Data
      final jsonList = scheduleList.map((e) => e.toJson()).toList();
      await hiveService.cacheSchedule(jsonList);

      // 4. Schedule Notifications
      _scheduleClassNotifications(scheduleList);

      emit(StudentScheduleLoaded());
    } catch (e) {
      log("CRITICAL StudentSchedule Fetch Error: $e");
      emit(StudentScheduleError(message: "Error loading schedule: $e"));
      
      // 3. Fallback to Hive
      final cachedData = hiveService.getCachedSchedule();
      if (cachedData != null) {
        try {
          // Hive stores as List<dynamic>, usually needs casting
           final List list = cachedData; // cachedData depends on implementation, usually List
           scheduleList = list.map((e) {
             // Ensure e is a Map<String, dynamic>
             return SubjectScheduleModel.fromJson(Map<String, dynamic>.from(e));
           }).toList();
           _applyFilter();
           log("Loaded ${scheduleList.length} items from Hive Cache.");
           emit(StudentScheduleLoaded());
        } catch (cacheError) {
          log("Cache parsing error: $cacheError");
          emit(StudentScheduleError(message: "Failed to load offline data."));
        }
      } else {
        emit(StudentScheduleError(message: e.toString()));
      }
    }
  }

  void _scheduleClassNotifications(List<SubjectScheduleModel> schedules) {
    try {
      final notificationService = getIt<EnhancedNotificationService>();
      
      // Cancel previous scheduled notifications to avoid duplicates when refreshing
      // Note: In a production app, we'd only cancel class-related IDs
      
      for (int i = 0; i < schedules.length; i++) {
        final schedule = schedules[i];
        final nextClassTime = calculateNextClassTime(schedule.dayOfWeek, schedule.timeSlot);
        
        if (nextClassTime != null) {
          // 1. 30 minutes before
          final reminderTime = nextClassTime.subtract(const Duration(minutes: 30));
          if (reminderTime.isAfter(DateTime.now())) {
            notificationService.scheduleNotification(
              id: 1000 + i, // Unique ID for reminder
              title: "Upcoming Lecture: ${schedule.subjectName}",
              body: "Starts in 30 mins at ${schedule.room?.name ?? 'Assigned Room'}. Tap for details 📍",
              scheduledTime: reminderTime,
              type: NotificationType.schedule,
              payload: schedule.room?.name ?? 'Assigned Room',
            );
          }

          // 2. At start time
          if (nextClassTime.isAfter(DateTime.now())) {
            notificationService.scheduleNotification(
              id: 2000 + i, // Unique ID for start
              title: "Lecture Starting: ${schedule.subjectName}",
              body: "Your lecture is starting now at ${schedule.room?.name ?? 'Assigned Room'}. Have a productive session!",
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

  DateTime? calculateNextClassTime(String dayName, String timeSlot) {
    try {
      // 1. Parse Day
      int targetWeekday = _getWeekdayIndex(dayName);
      if (targetWeekday == 0) return null;

      // 2. Parse Start Time (e.g., "08:00 AM")
      final parts = timeSlot.split('-');
      if (parts.isEmpty) return null;
      final startTimeString = parts[0].trim(); // "08:00 AM"

      final now = DateTime.now();
      final format = DateFormat("hh:mm a"); 
      final timeDate = format.parse(startTimeString);
      
      // Create a date for today with the class time
      var targetDate = DateTime(now.year, now.month, now.day, timeDate.hour, timeDate.minute);
      
      // Move to the correct day of week
      while (targetDate.weekday != targetWeekday) {
        targetDate = targetDate.add(const Duration(days: 1));
      }
      
      // If the resulting time is in the past, add 7 days (next week)
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

  // Returns the nearest upcoming class from the schedule
  Map<String, dynamic>? getNextUpcomingClass() {
    if (scheduleList.isEmpty) return null;
    
    DateTime? nearestTime;
    SubjectScheduleModel? nearestSubject;
    
    final now = DateTime.now();
    
    for (var schedule in scheduleList) {
      final classTime = calculateNextClassTime(schedule.dayOfWeek, schedule.timeSlot);
      if (classTime != null && classTime.isAfter(now)) {
        if (nearestTime == null || classTime.isBefore(nearestTime)) {
          nearestTime = classTime;
          nearestSubject = schedule;
        }
      }
    }
    
    if (nearestSubject != null && nearestTime != null) {
      return {
        'subject': nearestSubject,
        'time': nearestTime
      };
    }
    
    return null;
  }

  void _applyFilter() {
    if (_currentQuery.trim().isEmpty) {
      filterSchedule = scheduleList;
      return;
    }
    final q = _currentQuery.trim().toLowerCase();
    filterSchedule = scheduleList.where((schedule) {
      final subjectMatch = schedule.subjectName.toLowerCase().contains(q);
      final codeMatch = (schedule.subject?.code ?? '').toLowerCase().contains(q);
      final roomMatch = (schedule.room?.name ?? '').toLowerCase().contains(q);
      final dayMatch = schedule.dayOfWeek.toLowerCase().contains(q) || schedule.formattedDay.toLowerCase().contains(q);
      final timeMatch = schedule.timeSlot.toLowerCase().contains(q);
      return subjectMatch || codeMatch || roomMatch || dayMatch || timeMatch;
    }).toList();
  }

  void searchSchedule(String query) {
    _currentQuery = query;
    _applyFilter();
    emit(StudentScheduleLoaded());
  }
}
