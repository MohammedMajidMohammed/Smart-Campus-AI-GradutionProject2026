import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smart_canvas/features/online_sessions/models/online_session_model.dart';
import 'package:smart_canvas/features/online_sessions/services/online_sessions_service.dart';
import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';
import 'package:smart_canvas/core/services/enhanced_notification_service.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:smart_canvas/features/online_sessions/services/subject_chat_service.dart';

part 'online_sessions_state.dart';

class OnlineSessionsCubit extends Cubit<OnlineSessionsState> {
  final OnlineSessionsService _service;
  RealtimeChannel? _sessionsChannel;
  final _supabase = Supabase.instance.client;
  
  OnlineSessionsCubit(this._service) : super(OnlineSessionsInitial());

  /// Load sessions for professor
  Future<void> loadProfessorSessions() async {
    emit(OnlineSessionsLoading());
    try {
      final sessions = await _service.getProfessorSessions();
      emit(OnlineSessionsLoaded(sessions));
      
      // Schedule reminders for upcoming sessions
      _scheduleReminders(sessions);
    } catch (e) {
      emit(OnlineSessionsError(e.toString()));
    }
  }

  /// Load sessions for student
  Future<void> loadStudentSessions() async {
    emit(OnlineSessionsLoading());
    try {
      final sessions = await _service.getStudentSessions();
      emit(OnlineSessionsLoaded(sessions));
      
      // Schedule reminders for upcoming sessions
      _scheduleReminders(sessions);
    } catch (e) {
      emit(OnlineSessionsError(e.toString()));
    }
  }

  /// Load subjects for the professor to choose from
  Future<void> loadProfessorSubjects() async {
    try {
      final subjects = await _service.getProfessorSubjects();
      emit(OnlineSessionsSubjectsLoaded(subjects));
    } catch (e) {
      emit(OnlineSessionsError(e.toString()));
    }
  }

  /// Create a new session
  Future<void> createSession(OnlineSessionModel session) async {
    emit(OnlineSessionsLoading());
    try {
      final created = await _service.createOnlineSession(session);
      if (created != null) {
        emit(OnlineSessionsCreated(created));
        
        // Post a message to the subject chat
        getIt<SubjectChatService>().sendTextMessage(
          created.subjectId, 
          '📅 *${"session_scheduled".tr()}: ${created.title}*\n\n🕒 *${"starts_lbl".tr()}:* ${DateFormat('yyyy-MM-dd hh:mm a').format(created.startTime)}\n\n⏳ *${"duration_lbl".tr()}:* ${created.durationMinutes} ${"mins".tr()}\n\n🔗 *${"link_lbl".tr()}:* ${created.meetingLink}\n\n📢 *${"join_conversation_now".tr()}*'
        );

        loadProfessorSessions(); // Refresh list
      } else {
        emit(const OnlineSessionsError('Failed to create session'));
      }
    } catch (e) {
      emit(OnlineSessionsError(e.toString()));
    }
  }

  /// Update an existing session
  Future<void> updateSession(OnlineSessionModel session) async {
    emit(OnlineSessionsLoading());
    try {
      final updated = await _service.updateOnlineSession(session);
      if (updated != null) {
        loadProfessorSessions(); // Refresh list
      } else {
        emit(const OnlineSessionsError('Failed to update session'));
      }
    } catch (e) {
      emit(OnlineSessionsError(e.toString()));
    }
  }

  /// Delete a session
  Future<void> deleteSession(String sessionId) async {
    emit(OnlineSessionsLoading());
    try {
      final success = await _service.deleteOnlineSession(sessionId);
      if (success) {
        loadProfessorSessions(); // Refresh list
      } else {
        emit(const OnlineSessionsError('Failed to delete session'));
      }
    } catch (e) {
      emit(OnlineSessionsError(e.toString()));
    }
  }

  /// Schedule local notifications 15 minutes before sessions
  void _scheduleReminders(List<OnlineSessionModel> sessions) {
    final now = DateTime.now();
    final reminderService = getIt<EnhancedNotificationService>();
    
    for (final session in sessions) {
      final reminderTime = session.startTime.subtract(const Duration(minutes: 15));
      
      // Only schedule if the reminder time is in the future
      if (reminderTime.isAfter(now)) {
        reminderService.scheduleNotification(
          id: session.id.hashCode,
          title: 'Upcoming Online Session: ${session.title}',
          body: 'Your session for ${session.subjectName ?? "Subject"} starts in 15 minutes.',
          scheduledTime: reminderTime,
          payload: 'online_session_${session.id}',
        );
      }
    }
  }

  /// Subscribe to realtime online session updates
  void subscribeToSessions({required bool isProfessor}) {
    if (isProfessor) {
      loadProfessorSessions();
    } else {
      loadStudentSessions();
    }

    _sessionsChannel = _supabase.channel('public:online_sessions_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'online_sessions',
          callback: (payload) {
            if (isProfessor) {
              loadProfessorSessions();
            } else {
              loadStudentSessions();
            }
          },
        )
        .subscribe();
  }

  @override
  Future<void> close() {
    if (_sessionsChannel != null) {
      _supabase.removeChannel(_sessionsChannel!);
    }
    return super.close();
  }
}
