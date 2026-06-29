import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_canvas/features/student/dashboard/models/attendance_record_model.dart';

class AttendanceRepository {
  final SupabaseClient _supabase;

  AttendanceRepository(this._supabase);

  /// Fetch all attendance records for a specific student
  Future<List<AttendanceRecordModel>> getStudentAttendance(String studentId) async {
    try {
      final response = await _supabase
          .from('attendance_records')
          .select()
          .eq('student_id', studentId);
      
      return (response as List)
          .map((e) => AttendanceRecordModel.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to load attendance records: $e');
    }
  }

  /// Fetch attendance records with subject names for history display
  Future<List<Map<String, dynamic>>> getStudentAttendanceWithSubjects(String studentId) async {
    try {
      // 1. Fetch all attendance records for the student
      final recordsResponse = await _supabase
          .from('attendance_records')
          .select()
          .eq('student_id', studentId)
          .order('scanned_at', ascending: false);
      
      final records = recordsResponse as List<dynamic>;
      if (records.isEmpty) return [];

      // 2. Extract Session IDs
      final sessionIds = records.map((r) => r['session_id']).toSet().toList();

      // 3. Fetch Sessions manually
      final sessionsResponse = await _supabase
          .from('attendance_sessions')
          .select()
          .filter('id', 'in', sessionIds);
      final sessions = sessionsResponse as List<dynamic>;
      final sessionsMap = {for (var s in sessions) s['id']: s};

      // 4. Extract Subject IDs from sessions
      final subjectIds = sessions.map((s) => s['subject_id']).toSet().toList();

      // 5. Fetch Subjects manually
      final subjectsResponse = await _supabase
          .from('subjects')
          .select()
          .filter('id', 'in', subjectIds);
      final subjects = subjectsResponse as List<dynamic>;
      final subjectsMap = {for (var s in subjects) s['id']: s};
      
      // 6. Map and Group Data
      final Map<String, Map<String, dynamic>> grouped = {};

      for (final record in records) {
        final sessionId = record['session_id'];
        final session = sessionsMap[sessionId];
        if (session == null) continue;

        final subjectId = session['subject_id'];
        final subject = subjectsMap[subjectId];
        final subjectName = subject != null ? subject['name'] : 'Unknown Subject';

        final weekNumber = session['week_number'] as int? ?? record['week_number'] as int? ?? 0;
        final scannedAt = record['scanned_at'] as String?;

        if (!grouped.containsKey(subjectId)) {
          grouped[subjectId] = {
            'subject_id': subjectId,
            'subject_name': subjectName,
            'weeks': <int>[],
            'total_attended': 0,
            'last_attended': scannedAt,
          };
        }
        
        if (weekNumber > 0 && !(grouped[subjectId]!['weeks'] as List<int>).contains(weekNumber)) {
          (grouped[subjectId]!['weeks'] as List<int>).add(weekNumber);
        }
        grouped[subjectId]!['total_attended'] = (grouped[subjectId]!['total_attended'] as int) + 1;
      }

      // Sort weeks within each subject
      for (final entry in grouped.values) {
        (entry['weeks'] as List<int>).sort();
      }

      return grouped.values.toList();
    } catch (e) {
      throw Exception('Failed to load attendance history: $e');
    }
  }
  
  /// Get total count of enrolled subjects for the student
  Future<int> getEnrolledSubjectsCount(String studentId) async {
    try {
      // 1. Fetch student's profile info
      final profileData = await _supabase
          .from('users')
          .select('college_id, academic_year_id, year_level')
          .eq('id', studentId)
          .single();

      final collegeId = profileData['college_id'];
      final programId = profileData['academic_year_id'];
      final yearLevel = profileData['year_level'];

      if (collegeId == null || programId == null) return 6;

      // 2. Count subjects in subject_schedules for this level
      final scheduleData = await _supabase
          .from('subject_schedules')
          .select('subject_id, subjects!inner(college_id, academic_year_id)')
          .eq('subjects.college_id', collegeId)
          .eq('subjects.academic_year_id', programId)
          .eq('year_level', yearLevel ?? 1);

      final subjectIds = (scheduleData as List).map((item) => item['subject_id']).toSet();
      return subjectIds.isNotEmpty ? subjectIds.length : 6;
    } catch (e) {
      return 6;
    }
  }
}
