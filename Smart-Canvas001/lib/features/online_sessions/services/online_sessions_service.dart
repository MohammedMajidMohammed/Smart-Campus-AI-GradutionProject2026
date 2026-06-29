import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_canvas/features/online_sessions/models/online_session_model.dart';
import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';

class OnlineSessionsService {
  final _supabase = getIt<SupabaseClient>();

  /// Fetch subjects assigned to the current professor
  Future<List<SubjectModel>> getProfessorSubjects() async {
    final user = getIt<CacheHelper>().getUserModel();
    if (user == null) return [];

    try {
      // Fetch subject IDs from schedules where admin_id matches professor
      final response = await _supabase
          .from('subject_schedules')
          .select('subject_id, subjects(*)')
          .eq('admin_id', user.id);

      final List<dynamic> data = response as List<dynamic>;
      
      // Filter out duplicates and map to SubjectModel
      final Map<String, SubjectModel> subjectsMap = {};
      for (var item in data) {
        if (item['subjects'] != null) {
          final subject = SubjectModel.fromJson(item['subjects']);
          subjectsMap[subject.id] = subject;
        }
      }
      
      return subjectsMap.values.toList();
    } catch (e) {
      print('Error fetching professor subjects: $e');
      return [];
    }
  }

  /// Create a new online session
  Future<OnlineSessionModel?> createOnlineSession(OnlineSessionModel session) async {
    try {
      final response = await _supabase
          .from('online_sessions')
          .insert(session.toJson())
          .select('*, subjects(name), users!online_sessions_professor_id_fkey(full_name)')
          .single();

      return OnlineSessionModel.fromJson(response);
    } catch (e) {
      print('Error creating online session: $e');
      return null;
    }
  }

  /// Update an existing online session
  Future<OnlineSessionModel?> updateOnlineSession(OnlineSessionModel session) async {
    try {
      final response = await _supabase
          .from('online_sessions')
          .update(session.toJson())
          .eq('id', session.id)
          .select('*, subjects(name), users!online_sessions_professor_id_fkey(full_name)')
          .single();

      return OnlineSessionModel.fromJson(response);
    } catch (e) {
      print('Error updating online session: $e');
      return null;
    }
  }

  /// Delete an online session
  Future<bool> deleteOnlineSession(String sessionId) async {
    try {
      await _supabase
          .from('online_sessions')
          .delete()
          .eq('id', sessionId);
      return true;
    } catch (e) {
      print('Error deleting online session: $e');
      return false;
    }
  }

  /// Fetch online sessions for the current professor
  Future<List<OnlineSessionModel>> getProfessorSessions() async {
    final user = getIt<CacheHelper>().getUserModel();
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('online_sessions')
          .select('*, subjects(name), users!online_sessions_professor_id_fkey(full_name)')
          .eq('professor_id', user.id)
          .order('start_time', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((e) => OnlineSessionModel.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching professor sessions: $e');
      return [];
    }
  }

  /// Fetch online sessions for the current student
  Future<List<OnlineSessionModel>> getStudentSessions() async {
    final user = getIt<CacheHelper>().getUserModel();
    if (user == null) return [];

    try {
      // 1. Get student's subjects from schedules
      final scheduleResponse = await _supabase
          .from('subject_schedules')
          .select('subject_id')
          .eq('year_level', user.yearLevel ?? 1);
      
      final List<dynamic> scheduleData = scheduleResponse as List<dynamic>;
      final List<String> subjectIds = scheduleData.map((e) => e['subject_id'] as String).toList();

      if (subjectIds.isEmpty) return [];

      // 2. Fetch sessions for those subjects (fetch last 24 hours to include ongoing ones)
      final sessionResponse = await _supabase
          .from('online_sessions')
          .select('*, subjects(name), users!online_sessions_professor_id_fkey(full_name)')
          .inFilter('subject_id', subjectIds)
          .gte('start_time', DateTime.now().subtract(const Duration(hours: 24)).toUtc().toIso8601String())
          .order('start_time', ascending: true);

      final List<dynamic> sessionData = sessionResponse as List<dynamic>;
      final allSessions = sessionData.map((e) => OnlineSessionModel.fromJson(e)).toList();
      
      // 3. Filter sessions that haven't finished yet or are upcoming
      return allSessions.where((session) {
        final endTime = session.startTime.add(Duration(minutes: session.durationMinutes));
        return endTime.isAfter(DateTime.now());
      }).toList();
    } catch (e) {
      print('Error fetching student sessions: $e');
      return [];
    }
  }
}
