import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:csv/csv.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';
import 'package:smart_canvas/features/administrator/schedule/models/subject_schedule_model.dart';
import 'package:uuid/uuid.dart';

part 'professor_attendance_state.dart';

class ProfessorAttendanceCubit extends Cubit<ProfessorAttendanceState> {
  ProfessorAttendanceCubit() : super(ProfessorAttendanceInitial());

  final supabase = getIt<SupabaseClient>();
  String? sessionId;
  String? currentToken;
  String? currentPin;
  int attendeeCount = 0;
  Timer? _refreshTimer;
  RealtimeChannel? _attendanceSubscription;
  List<SubjectModel> professorSubjects = [];

  // -- Functions -- //

  Future<void> getProfessorSubjects() async {
    try {
      emit(ProfessorAttendanceLoading());
      
      final currentUserId = supabase.auth.currentUser!.id;
      final res = await supabase.rpc('get_subject_schedules_with_subject');
      
      if (res == null) {
        professorSubjects = [];
      } else {
        final List schedulesList = res as List;
        final List<SubjectScheduleModel> allSchedules = schedulesList
            .map((e) => SubjectScheduleModel.fromJson(e as Map<String, dynamic>))
            .toList();
            
        final professorSchedule = allSchedules.where((e) => e.adminId == currentUserId).toList();
        
        final Map<String, SubjectModel> uniqueSubjects = {};
        for (var schedule in professorSchedule) {
          if (schedule.subject != null) {
            uniqueSubjects[schedule.subject!.id] = schedule.subject!;
          }
        }
        professorSubjects = uniqueSubjects.values.toList();
      }
      
      emit(GetSubjectsSuccess(subjects: professorSubjects));
    } catch (e) {
      log("Error fetching professor subjects: $e");
      emit(ProfessorAttendanceError(message: e.toString()));
    }
  }

  Future<void> startAttendanceSession({required String subjectId, required int weekNumber}) async {
    try {
      emit(ProfessorAttendanceLoading());

      // 1. Generate initial token and pin
      currentToken = const Uuid().v4();
      currentPin = (math.Random().nextInt(9000) + 1000).toString();

      // 2. Call RPC to start session
      final response = await supabase.rpc('start_attendance_session', params: {
        'p_subject_id': subjectId,
        'p_admin_id': supabase.auth.currentUser!.id,
        'p_token': currentToken,
        'p_pin': currentPin,
        'p_duration_minutes': 10,
        'p_week_number': weekNumber,
      });

      sessionId = response as String;

      // 3. Fetch initial count of attendees for this session
      await _fetchAttendeeCount();

      // 4. Start Timer to refresh token every 5 minutes
      _startTokenRefreshTimer(subjectId);

      // 5. Subscribe to attendance_records to count attendees in real-time
      _subscribeToAttendance();

      emit(ProfessorAttendanceStarted(
        token: currentToken!,
        pin: currentPin!,
        attendeeCount: attendeeCount,
      ));
    } catch (e) {
      log("Error starting attendance session: $e");
      emit(ProfessorAttendanceError(message: e.toString()));
    }
  }

  /// Fetch the current attendee count for this session
  Future<void> _fetchAttendeeCount() async {
    if (sessionId == null) return;
    try {
      final count = await supabase
          .from('attendance_records')
          .count(CountOption.exact)
          .eq('session_id', sessionId!);
      attendeeCount = count;
    } catch (e) {
      log("Error fetching attendee count: $e");
    }
  }

  void _startTokenRefreshTimer(String subjectId) {
    _refreshTimer?.cancel();
    // Refresh Token every 5 minutes
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      // 1. Poll for latest attendee count (Fallback for Realtime)
      await _fetchAttendeeCount();
      
      // 2. Refresh Token every 5 minutes (300 * 1s = 300s)
      if (timer.tick % 300 == 0) {
        currentToken = const Uuid().v4();
        await supabase.from('attendance_sessions').update({
          'session_token': currentToken,
        }).eq('id', sessionId!);
      }
      
      if (!isClosed) {
        emit(ProfessorAttendanceStarted(
          token: currentToken!,
          pin: currentPin!,
          attendeeCount: attendeeCount,
        ));
      }
    });
  }

  void _subscribeToAttendance() {
    _attendanceSubscription?.unsubscribe();
    
    if (sessionId == null) return;

    _attendanceSubscription = supabase
        .channel('attendance_session_$sessionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'attendance_records',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId!,
          ),
          callback: (payload) {
            attendeeCount++;
            if (state is ProfessorAttendanceStarted) {
              emit(ProfessorAttendanceStarted(
                token: currentToken!,
                pin: currentPin!,
                attendeeCount: attendeeCount,
              ));
            }
          },
        )
        .subscribe();
  }

  /// Export attendance records for this session as a CSV file (opens in Excel)
  Future<void> exportAttendanceExcel(String subjectName, int weekNumber) async {
    try {
      if (sessionId == null) throw "No active session";

      // 1. Fetch records
      final response = await supabase
          .from('attendance_records')
          .select('student_name, college_id, scanned_at')
          .eq('session_id', sessionId!)
          .order('scanned_at', ascending: true);

      final List<dynamic> records = response as List<dynamic>;

      if (records.isEmpty) {
        emit(ProfessorAttendanceError(message: "No attendance records found yet."));
        emit(ProfessorAttendanceStarted(
          token: currentToken!,
          pin: currentPin!,
          attendeeCount: attendeeCount,
        ));
        return;
      }

      // 2. Build CSV data
      final List<List<String>> csvData = [
        ['#', 'Student Name', 'College ID', 'Time'], // Header
      ];

      for (int i = 0; i < records.length; i++) {
        final record = records[i];
        final scannedAt = DateTime.tryParse(record['scanned_at'] ?? '');
        final timeStr = scannedAt != null
            ? '${scannedAt.hour.toString().padLeft(2, '0')}:${scannedAt.minute.toString().padLeft(2, '0')}'
            : '';
        
        csvData.add([
          '${i + 1}',
          record['student_name'] ?? 'N/A',
          record['college_id'] ?? 'N/A',
          timeStr,
        ]);
      }

      final csvString = const ListToCsvConverter().convert(csvData);

      // 3. Save file
      Directory? dir;
      if (Platform.isAndroid) {
        // Try getting external storage directory
        dir = await getExternalStorageDirectory();
      } 
      // Fallback
      dir ??= await getApplicationDocumentsDirectory();
      
      final fileName = '${subjectName}_Week${weekNumber}_Attendance.csv';
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(csvString, encoding: utf8);

      log("Exported to: $filePath");
      // Could show a snackbar here if we had context, but we are in cubit.
      // We can emit a specific state or just let the user know via log/debug for now
      // or repurpose the error state to show a "success" toast with the path.
      emit(ProfessorAttendanceError(message: "Saved to: $filePath"));
      
      // Re-emit started state to keep UI active
      emit(ProfessorAttendanceStarted(
        token: currentToken!,
        pin: currentPin!,
        attendeeCount: attendeeCount,
      ));

    } catch (e) {
      log("Export error: $e");
      emit(ProfessorAttendanceError(message: "Export failed: $e"));
      // Re-emit started state
      if (currentToken != null && currentPin != null) {
        emit(ProfessorAttendanceStarted(
          token: currentToken!,
          pin: currentPin!,
          attendeeCount: attendeeCount,
        ));
      }
    }
  }

  Future<void> stopAttendanceSession() async {
    _refreshTimer?.cancel();
    _attendanceSubscription?.unsubscribe();
    
    try {
      if (sessionId != null) {
        await supabase
            .from('attendance_sessions')
            .update({'is_active': false})
            .eq('id', sessionId!);
      }
    } catch (e) {
      log("Error stopping session: $e");
    }
    
    emit(ProfessorAttendanceInitial());
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    _attendanceSubscription?.unsubscribe();
    return super.close();
  }
}
