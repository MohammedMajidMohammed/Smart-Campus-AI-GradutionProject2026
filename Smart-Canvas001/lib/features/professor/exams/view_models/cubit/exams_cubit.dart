import 'package:bloc/bloc.dart';
import 'package:smart_canvas/features/professor/exams/models/exam_model.dart';
import 'package:smart_canvas/features/professor/exams/models/exam_question_model.dart';
import 'package:smart_canvas/features/professor/exams/models/exam_submission_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'exams_state.dart';

class ExamsCubit extends Cubit<ExamsState> {
  ExamsCubit() : super(ExamsInitial());

  final _supabase = Supabase.instance.client;
  RealtimeChannel? _examsChannel;

  /// Load all exams for the current professor
  Future<void> loadExams() async {
    emit(ExamsLoading());
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        emit(ExamsError('Not logged in'));
        return;
      }

      final data = await _supabase
          .from('exams')
          .select('*, subjects(name), exam_questions(id)')
          .eq('professor_id', user.id)
          .order('created_at', ascending: false);

      final exams = (data as List).map((e) => ExamModel.fromJson(e)).toList();
      emit(ExamsLoaded(exams));
    } catch (e) {
      emit(ExamsError(e.toString()));
    }
  }

  /// Load subjects assigned to this professor (from subject_schedules)
  Future<List<Map<String, dynamic>>> loadProfessorSubjects() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final data = await _supabase
          .from('subject_schedules')
          .select('subject_id, subjects(id, name)')
          .eq('admin_id', user.id);

      // Deduplicate by subject_id
      final seen = <String>{};
      final subjects = <Map<String, dynamic>>[];
      for (final item in data as List) {
        final subj = item['subjects'];
        if (subj != null && seen.add(subj['id'].toString())) {
          subjects.add(Map<String, dynamic>.from(subj));
        }
      }
      return subjects;
    } catch (e) {
      return [];
    }
  }

  /// Create a new exam
  Future<String?> createExam({
    required String subjectId,
    required String title,
    String? description,
    required DateTime openAt,
    required DateTime closeAt,
    required int durationMinutes,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final result = await _supabase.from('exams').insert({
        'subject_id': subjectId,
        'professor_id': user.id,
        'title': title,
        'description': description,
        'open_at': openAt.toUtc().toIso8601String(),
        'close_at': closeAt.toUtc().toIso8601String(),
        'duration_minutes': durationMinutes,
        'is_active': true,
      }).select('id').single();

      return result['id']?.toString();
    } catch (e) {
      emit(ExamsError(e.toString()));
      return null;
    }
  }

  /// Update an existing exam
  Future<bool> updateExam({
    required String examId,
    required String title,
    String? description,
    required DateTime openAt,
    required DateTime closeAt,
    required int durationMinutes,
  }) async {
    try {
      await _supabase.from('exams').update({
        'title': title,
        'description': description,
        'open_at': openAt.toUtc().toIso8601String(),
        'close_at': closeAt.toUtc().toIso8601String(),
        'duration_minutes': durationMinutes,
      }).eq('id', examId);
      
      await loadExams();
      return true;
    } catch (e) {
      emit(ExamsError(e.toString()));
      return false;
    }
  }

  /// Add a question to an exam
  Future<bool> addQuestion(ExamQuestionModel question) async {
    try {
      await _supabase.from('exam_questions').insert(question.toInsertJson());
      return true;
    } catch (e) {
      emit(ExamsError(e.toString()));
      return false;
    }
  }

  /// Load questions for an exam
  Future<List<ExamQuestionModel>> loadQuestions(String examId) async {
    try {
      final data = await _supabase
          .from('exam_questions')
          .select()
          .eq('exam_id', examId)
          .order('sort_order');

      return (data as List).map((e) => ExamQuestionModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete a question
  Future<bool> deleteQuestion(String questionId) async {
    try {
      await _supabase.from('exam_questions').delete().eq('id', questionId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete an exam
  Future<bool> deleteExam(String examId) async {
    try {
      await _supabase.from('exams').delete().eq('id', examId);
      await loadExams();
      return true;
    } catch (e) {
      emit(ExamsError(e.toString()));
      return false;
    }
  }

  /// Toggle exam active status
  Future<void> toggleExamActive(String examId, bool isActive) async {
    try {
      await _supabase.from('exams').update({'is_active': isActive}).eq('id', examId);
      await loadExams();
    } catch (e) {
      emit(ExamsError(e.toString()));
    }
  }

  /// Load exam results (all student submissions)
  Future<List<ExamSubmissionModel>> loadExamResults(String examId) async {
    try {
      final data = await _supabase
          .from('exam_submissions')
          .select('*, users(full_name, image)')
          .eq('exam_id', examId)
          .eq('is_submitted', true)
          .order('score', ascending: false);

      return (data as List).map((e) => ExamSubmissionModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Load all answers for a specific submission (for professor review)
  Future<List<Map<String, dynamic>>> loadSubmissionAnswers(String submissionId) async {
    try {
      final data = await _supabase
          .from('exam_answers')
          .select('*, exam_questions(*)')
          .eq('submission_id', submissionId)
          .order('id');
      
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  /// Update scores for a submission (manual grading)
  Future<bool> updateSubmissionGrades(String submissionId, Map<String, double> grades) async {
    try {
      double totalScore = 0;

      for (final entry in grades.entries) {
        final answerId = entry.key;
        final points = entry.value;

        await _supabase
            .from('exam_answers')
            .update({
              'points_earned': points,
              'is_correct': points > 0,
            })
            .eq('id', answerId);
      }

      // Recalculate total score
      final answers = await _supabase
          .from('exam_answers')
          .select('points_earned')
          .eq('submission_id', submissionId);
      
      for (final a in answers as List) {
        totalScore += (a['points_earned'] as num).toDouble();
      }

      await _supabase
          .from('exam_submissions')
          .update({'score': totalScore})
          .eq('id', submissionId);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Subscribe to realtime changes on exams
  void subscribeToRealtimeExams() {
    loadExams(); // Initial load

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _examsChannel = _supabase.channel('public:professor_exams')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'exams',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'professor_id',
            value: user.id,
          ),
          callback: (payload) {
            loadExams();
          },
        )
        .subscribe();
  }

  @override
  Future<void> close() {
    if (_examsChannel != null) {
      _supabase.removeChannel(_examsChannel!);
    }
    return super.close();
  }
}
