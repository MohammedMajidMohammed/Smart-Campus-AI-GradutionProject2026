import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:smart_canvas/features/professor/assignments/services/assignments_service.dart';
import 'package:smart_canvas/features/online_sessions/services/online_sessions_service.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/core/services/enhanced_notification_service.dart';
import 'upcoming_deadlines_state.dart';

class UpcomingDeadlinesCubit extends Cubit<UpcomingDeadlinesState> {
  final AssignmentsService _assignmentsService = getIt<AssignmentsService>();
  final OnlineSessionsService _sessionsService = getIt<OnlineSessionsService>();
  final _supabase = getIt<SupabaseClient>();

  RealtimeChannel? _examsChannel;
  RealtimeChannel? _assignmentsChannel;
  RealtimeChannel? _sessionsChannel;

  UpcomingDeadlinesCubit() : super(UpcomingDeadlinesInitial());

  Future<void> loadDeadlines() async {
    emit(UpcomingDeadlinesLoading());
    try {
      final user = getIt<CacheHelper>().getUserModel();
      if (user == null) {
        emit(UpcomingDeadlinesLoaded(const []));
        return;
      }

      await _checkNewMaterials();

      final now = DateTime.now();

      // 1. Fetch Assignments
      final assignments = await _assignmentsService.getStudentUpcomingAssignments();
      final assignmentItems = assignments.map((a) => DeadlineItem(
        id: a.id,
        title: a.title,
        subject: a.subjectName ?? 'Subject',
        dueDate: a.dueDate,
        endDate: a.dueDate, // Assignments disappear exactly at due date
        icon: Icons.assignment_outlined,
        color: const Color(0xFF8B5CF6),
        type: 'assignment',
      )).toList();

      // 2. Fetch Online Sessions
      final sessions = await _sessionsService.getStudentSessions();
      final sessionItems = sessions.map((s) => DeadlineItem(
        id: s.id,
        title: s.title,
        subject: s.subjectName ?? 'Subject',
        dueDate: s.startTime,
        endDate: s.startTime.add(Duration(minutes: s.durationMinutes)), // Dynamically use session duration
        icon: Icons.video_call_outlined,
        color: const Color(0xFF10B981),
        type: 'session',
      )).toList();

      // 3. Fetch Exams (filtered by student's subjects from schedules)
      final scheduleResponse = await _supabase
          .from('subject_schedules')
          .select('subject_id')
          .eq('year_level', user.yearLevel ?? 1);
      
      final List<dynamic> scheduleData = scheduleResponse as List<dynamic>;
      final List<String> subjectIds = scheduleData.map((e) => e['subject_id'] as String).toList();

      List<DeadlineItem> examItems = [];
      if (subjectIds.isNotEmpty) {
        final examResponse = await _supabase
            .from('exams')
            .select('id, title, subjects(name), open_at, close_at')
            .eq('is_active', true)
            .inFilter('subject_id', subjectIds)
            .gte('close_at', DateTime.now().toUtc().toIso8601String())
            .order('open_at', ascending: true)
            .limit(5);
        
        examItems = (examResponse as List).map((e) {
          final openAt = DateTime.parse(e['open_at'] as String).toLocal();
          final closeAt = DateTime.parse(e['close_at'] as String).toLocal();
          return DeadlineItem(
            id: e['id'] as String,
            title: e['title'] as String,
            subject: e['subjects'] != null ? e['subjects']['name'] as String : 'Exam',
            dueDate: openAt,
            endDate: closeAt, // Exams disappear exactly when they close
            icon: Icons.quiz_outlined,
            color: const Color(0xFFEF4444),
            type: 'exam',
          );
        }).toList();
      }

      // Combine and Filter out any that have ALREADY passed their endDate locally
      final allDeadlines = [...assignmentItems, ...sessionItems, ...examItems]
          .where((item) => item.endDate?.isAfter(now) ?? true)
          .toList();

      allDeadlines.sort((a, b) => a.dueDate.compareTo(b.dueDate));

      final result = allDeadlines.take(10).toList();
      emit(UpcomingDeadlinesLoaded(result));
      
      _scheduleNotifications(result);
    } catch (e) {
      debugPrint('Error loading deadlines: $e');
      emit(UpcomingDeadlinesError(e.toString()));
    }
  }

  void _scheduleNotifications(List<DeadlineItem> deadlines) {
    try {
      final notificationService = getIt<EnhancedNotificationService>();
      final now = DateTime.now();
      
      for (final item in deadlines) {
        // Reminder 30 mins before
        final reminderTime = item.dueDate.subtract(const Duration(minutes: 30));
        if (reminderTime.isAfter(now)) {
          notificationService.scheduleNotification(
            id: item.id.hashCode + 1,
            title: "Reminder: ${item.title}",
            body: "The event for ${item.subject} starts in 30 minutes!",
            scheduledTime: reminderTime,
            type: NotificationType.schedule,
          );
        }

        // Exact time notification
        if (item.dueDate.isAfter(now)) {
          notificationService.scheduleNotification(
            id: item.id.hashCode,
            title: "Started Now: ${item.title}",
            body: "It's time for ${item.subject}. Tap to join!",
            scheduledTime: item.dueDate,
            type: NotificationType.schedule,
          );
        }
      }
    } catch (e) {
      debugPrint('Error scheduling notifications: $e');
    }
  }

  Future<void> _checkNewMaterials() async {
    try {
      final cache = getIt<CacheHelper>();
      final lastCheckStr = cache.getData(key: 'last_material_check') as String?;
      final lastCheck = lastCheckStr != null ? DateTime.parse(lastCheckStr) : DateTime.now().subtract(const Duration(hours: 24));

      final response = await _supabase
          .from('materials')
          .select('title, subjects(name), created_at')
          .gt('created_at', lastCheck.toUtc().toIso8601String());

      final newMaterials = response as List;
      final notificationService = getIt<EnhancedNotificationService>();

      for (var mat in newMaterials) {
        await notificationService.showNotification(
          id: mat['created_at'].hashCode,
          title: "New Material: ${mat['title']}",
          body: "A new file was uploaded for ${mat['subjects']['name']}.",
          type: NotificationType.material,
        );
      }

      await cache.saveData(key: 'last_material_check', value: DateTime.now().toUtc().toIso8601String());
    } catch (e) {
      debugPrint('Error checking new materials: $e');
    }
  }

  /// Subscribe to realtime updates for exams, assignments, and online sessions
  void subscribeToDeadlines() {
    loadDeadlines(); // Initial load

    _examsChannel = _supabase.channel('public:exams_deadlines')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'exams',
          callback: (payload) => loadDeadlines(),
        )
        .subscribe();

    _assignmentsChannel = _supabase.channel('public:assignments_deadlines')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'assignments',
          callback: (payload) => loadDeadlines(),
        )
        .subscribe();

    _sessionsChannel = _supabase.channel('public:sessions_deadlines')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'online_sessions',
          callback: (payload) => loadDeadlines(),
        )
        .subscribe();
  }

  @override
  Future<void> close() {
    if (_examsChannel != null) _supabase.removeChannel(_examsChannel!);
    if (_assignmentsChannel != null) _supabase.removeChannel(_assignmentsChannel!);
    if (_sessionsChannel != null) _supabase.removeChannel(_sessionsChannel!);
    return super.close();
  }
}
