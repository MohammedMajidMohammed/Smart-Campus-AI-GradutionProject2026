import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_canvas/features/professor/assignments/models/assignment_model.dart';
import 'package:smart_canvas/features/professor/assignments/models/assignment_submission_model.dart';
import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';

class AssignmentsService {
  final _supabase = getIt<SupabaseClient>();

  /// Fetch subjects assigned to the current professor (reuse logic)
  Future<List<SubjectModel>> getProfessorSubjects() async {
    final user = getIt<CacheHelper>().getUserModel();
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('subject_schedules')
          .select('subject_id, subjects(*)')
          .eq('admin_id', user.id);

      final List<dynamic> data = response as List<dynamic>;
      
      final Map<String, SubjectModel> subjectsMap = {};
      for (var item in data) {
        if (item['subjects'] != null) {
          final subject = SubjectModel.fromJson(item['subjects']);
          subjectsMap[subject.id] = subject;
        }
      }
      return subjectsMap.values.toList();
    } catch (e) {
      print('Error fetching professor subjects for assignments: $e');
      return [];
    }
  }

  /// Create a new assignment
  Future<AssignmentModel?> createAssignment(AssignmentModel assignment, File? file, String? fileExt) async {
    try {
      String? fileUrl = assignment.fileUrl;
      
      // Upload file if provided
      if (file != null && fileExt != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'assignments/${assignment.professorId}/$timestamp.$fileExt';
        
        await _supabase.storage.from('materials').upload(fileName, file);
        fileUrl = _supabase.storage.from('materials').getPublicUrl(fileName);
      }
      
      final data = assignment.toJson();
      data.removeWhere((key, value) => value == null); // Remove nulls to prevent constraint issues
      data['file_url'] = fileUrl; // update with uploaded url

      final response = await _supabase
          .from('assignments')
          .insert(data)
          .select('*, subjects(name), users!assignments_professor_id_fkey(full_name)')
          .maybeSingle();

      return response != null ? AssignmentModel.fromJson(response) : null;
    } catch (e) {
      print('Error creating assignment: $e');
      throw Exception('Database Error: $e');
    }
  }

  /// Update an existing assignment
  Future<AssignmentModel?> updateAssignment(AssignmentModel assignment, File? file, String? fileExt) async {
    try {
      String? fileUrl = assignment.fileUrl;
      
      // Upload new file if provided
      if (file != null && fileExt != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'assignments/${assignment.professorId}/$timestamp.$fileExt';
        
        await _supabase.storage.from('materials').upload(fileName, file);
        fileUrl = _supabase.storage.from('materials').getPublicUrl(fileName);
      }
      
      final data = assignment.toJson();
      data.removeWhere((key, value) => value == null);
      data['file_url'] = fileUrl;

      final response = await _supabase
          .from('assignments')
          .update(data)
          .eq('id', assignment.id)
          .select('*, subjects(name), users!assignments_professor_id_fkey(full_name)')
          .maybeSingle();

      return response != null ? AssignmentModel.fromJson(response) : null;
    } catch (e) {
      print('Error updating assignment: $e');
      throw Exception('Database Error: $e');
    }
  }

  /// Delete an assignment
  Future<bool> deleteAssignment(String assignmentId) async {
    try {
      // Could also delete file from storage here, but omitting for simplicity
      await _supabase
          .from('assignments')
          .delete()
          .eq('id', assignmentId);
      return true;
    } catch (e) {
      print('Error deleting assignment: $e');
      return false;
    }
  }

  /// Fetch assignments for the current professor
  Future<List<AssignmentModel>> getProfessorAssignments() async {
    final user = getIt<CacheHelper>().getUserModel();
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('assignments')
          .select('*, subjects(name), users!assignments_professor_id_fkey(full_name)')
          .eq('professor_id', user.id)
          .order('due_date', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((e) => AssignmentModel.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching professor assignments: $e');
      return [];
    }
  }

  /// Fetch student submissions for a specific assignment
  Future<List<AssignmentSubmissionModel>> getAssignmentSubmissions(String assignmentId) async {
    try {
      final response = await _supabase
          .from('assignment_submissions')
          .select('*, users!assignment_submissions_student_id_fkey(full_name)')
          .eq('assignment_id', assignmentId)
          .order('submitted_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((e) => AssignmentSubmissionModel.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching assignment submissions: $e');
      return [];
    }
  }

  /// Fetch upcoming assignments for the current student
  Future<List<AssignmentModel>> getStudentUpcomingAssignments() async {
    final user = getIt<CacheHelper>().getUserModel();
    if (user == null) return [];

    try {
      final scheduleResponse = await _supabase
          .from('subject_schedules')
          .select('subject_id')
          .eq('year_level', user.yearLevel ?? 1);
      
      final List<dynamic> scheduleData = scheduleResponse as List<dynamic>;
      final List<String> subjectIds = scheduleData.map((e) => e['subject_id'] as String).toList();

      if (subjectIds.isEmpty) return [];

      final response = await _supabase
          .from('assignments')
          .select('*, subjects(name), users!assignments_professor_id_fkey(full_name)')
          .inFilter('subject_id', subjectIds)
          .gte('due_date', DateTime.now().toUtc().toIso8601String())
          .eq('is_active', true)
          .order('due_date', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((e) => AssignmentModel.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching student assignments: $e');
      return [];
    }
  }

  /// Submit an assignment (Student)
  Future<AssignmentSubmissionModel?> submitAssignment({
    required String assignmentId, 
    required File file, 
    required String fileExt
  }) async {
    final user = getIt<CacheHelper>().getUserModel();
    if (user == null) return null;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'submissions/${user.id}/$assignmentId/$timestamp.$fileExt';
      
      await _supabase.storage.from('materials').upload(fileName, file);
      final fileUrl = _supabase.storage.from('materials').getPublicUrl(fileName);
      
      final Map<String, dynamic> data = {
        'assignment_id': assignmentId,
        'student_id': user.id,
        'file_url': fileUrl,
      };

      // Upsert to handle multiple submissions
      final response = await _supabase
          .from('assignment_submissions')
          .upsert(data, onConflict: "assignment_id,student_id")
          .select('*, users!assignment_submissions_student_id_fkey(full_name)')
          .single();

      return AssignmentSubmissionModel.fromJson(response);
    } catch (e) {
      print('Error submitting assignment: $e');
      return null;
    }
  }
}
