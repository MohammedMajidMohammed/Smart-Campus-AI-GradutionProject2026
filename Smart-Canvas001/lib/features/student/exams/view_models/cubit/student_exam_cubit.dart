import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:smart_canvas/features/professor/exams/models/exam_model.dart';
import 'package:smart_canvas/features/professor/exams/models/exam_question_model.dart';
import 'package:smart_canvas/features/professor/exams/models/exam_submission_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'student_exam_state.dart';

class StudentExamCubit extends Cubit<StudentExamState> {
  StudentExamCubit() : super(StudentExamInitial());

  final _supabase = Supabase.instance.client;
  RealtimeChannel? _examsChannel;
  RealtimeChannel? _submissionsChannel;

  /// Load available exams for the student
  Future<void> loadAvailableExams() async {
    emit(StudentExamLoading());
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        emit(StudentExamError('Not logged in'));
        return;
      }

      // 1. Fetch student's profile info (college, program, year)
      final profileData = await _supabase
          .from('users')
          .select('college_id, academic_year_id, year_level')
          .eq('id', user.id)
          .single();

      final collegeId = profileData['college_id'];
      final programId = profileData['academic_year_id'];
      final yearLevel = profileData['year_level'];

      if (collegeId == null || programId == null) {
        emit(StudentExamError('Please complete your profile (College & Program) in Settings.'));
        return;
      }

      // 2. Fetch subjects and professors assigned to this student in subject_schedules
      final scheduleData = await _supabase
          .from('subject_schedules')
          .select('subject_id, admin_id, subjects!inner(college_id, academic_year_id)')
          .eq('subjects.college_id', collegeId)
          .eq('subjects.academic_year_id', programId)
          .eq('year_level', yearLevel ?? 1);

      // Create a set of (subject_id, professor_id) pairs
      final scheduledPairs = <String>{};
      for (final item in scheduleData as List) {
        final subjId = item['subject_id'];
        final profId = item['admin_id'];
        if (subjId != null && profId != null) {
          scheduledPairs.add('${subjId}_$profId');
        }
      }

      // 3. Fetch all active exams with subject + professor info
      final data = await _supabase
          .from('exams')
          .select('*, subjects(name), users!exams_professor_id_fkey(full_name)')
          .eq('is_active', true)
          .order('open_at', ascending: false);

      final allExamsRaw = (data as List).map((e) => ExamModel.fromJson(e)).toList();

      // 4. Filter exams by student's scheduled pairs
      final allExams = allExamsRaw.where((e) {
        return scheduledPairs.contains('${e.subjectId}_${e.professorId}');
      }).toList();

      // 5. Check which tasks the student has already submitted
      final submittedData = await _supabase
          .from('exam_submissions')
          .select('id, exam_id, is_submitted, score, total_points')
          .eq('student_id', user.id);

      final submittedExamIds = <String>{};
      for (final sub in submittedData as List) {
        if (sub['is_submitted'] == true) {
          submittedExamIds.add(sub['exam_id'].toString());
        }
      }

      final available = allExams
          .where((e) => !submittedExamIds.contains(e.id) && !e.isClosed)
          .toList();

      // For completed, we want the submission details (score, etc.)
      final completed = <Map<String, dynamic>>[];
      for (final sub in submittedData as List) {
        if (sub['is_submitted'] == true) {
          final exam = allExamsRaw.firstWhere((e) => e.id == sub['exam_id'], orElse: () => allExamsRaw.first);
          completed.add({
            'exam': exam,
            'submission': sub,
          });
        }
      }

      emit(StudentExamsLoaded(
        available: available,
        completed: completed,
      ));
    } catch (e) {
      emit(StudentExamError(e.toString()));
    }
  }

  /// Real-time subscription setup
  void subscribeToRealTimeChanges() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    loadAvailableExams(); // Initial load

    // 1. Listen for new exams
    if (_examsChannel != null) _supabase.removeChannel(_examsChannel!);
    _examsChannel = _supabase.channel('public:student_exams')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'exams',
          callback: (payload) {
            loadAvailableExams();
          },
        )
        .subscribe();

    // 2. Listen for submission changes (e.g. grading or new submissions)
    if (_submissionsChannel != null) _supabase.removeChannel(_submissionsChannel!);
    _submissionsChannel = _supabase.channel('public:student_submissions')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'exam_submissions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: user.id,
          ),
          callback: (payload) {
            loadAvailableExams();
          },
        )
        .subscribe();
  }

  @override
  Future<void> close() {
    if (_examsChannel != null) _supabase.removeChannel(_examsChannel!);
    if (_submissionsChannel != null) _supabase.removeChannel(_submissionsChannel!);
    return super.close();
  }

  /// Start an exam — create a submission record
  Future<String?> startExam(String examId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // Check if already started
      final existing = await _supabase
          .from('exam_submissions')
          .select('id')
          .eq('exam_id', examId)
          .eq('student_id', user.id)
          .maybeSingle();

      if (existing != null) return existing['id'].toString();

      final result = await _supabase.from('exam_submissions').insert({
        'exam_id': examId,
        'student_id': user.id,
        'started_at': DateTime.now().toUtc().toIso8601String(),
        'is_submitted': false,
      }).select('id').single();

      return result['id'].toString();
    } catch (e) {
      return null;
    }
  }

  /// Load questions for an exam
  Future<List<ExamQuestionModel>> loadExamQuestions(String examId) async {
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

  /// Submit the entire exam with all answers
  Future<ExamSubmissionModel?> submitExam({
    required String submissionId,
    required String examId,
    required List<ExamQuestionModel> questions,
    required Map<String, String> answers,
  }) async {
    try {
      double totalScore = 0;
      int totalPoints = 0;

      final List<Map<String, dynamic>> answersToInsert = [];
      for (final question in questions) {
        final studentAnswer = answers[question.id] ?? '';
        final pointsEarned = question.gradeAnswer(studentAnswer);
        final isCorrect = question.isMcq
            ? studentAnswer.trim().toLowerCase() ==
                question.correctAnswer.trim().toLowerCase()
            : pointsEarned > 0;

        totalScore += pointsEarned;
        totalPoints += question.points;

        answersToInsert.add({
          'submission_id': submissionId,
          'question_id': question.id,
          'student_answer': studentAnswer,
          'is_correct': isCorrect,
          'points_earned': pointsEarned,
        });
      }

      // Bulk insert for better reliability and performance
      await _supabase.from('exam_answers').insert(answersToInsert);

      final result = await _supabase
          .from('exam_submissions')
          .update({
            'score': totalScore,
            'total_points': totalPoints,
            'submitted_at': DateTime.now().toUtc().toIso8601String(),
            'is_submitted': true,
          })
          .eq('id', submissionId)
          .select('*, exams(title)')
          .single();

      return ExamSubmissionModel.fromJson(result);
    } catch (e) {
      return null;
    }
  }

  /// Load student's exam history
  Future<List<ExamSubmissionModel>> loadExamHistory() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final data = await _supabase
          .from('exam_submissions')
          .select('*, exams(title, subjects(name))')
          .eq('student_id', user.id)
          .eq('is_submitted', true)
          .order('submitted_at', ascending: false);

      return (data as List).map((e) {
        final map = Map<String, dynamic>.from(e);
        if (map['exams'] != null && map['exams']['subjects'] != null) {
          map['subject_name'] = map['exams']['subjects']['name'];
        }
        return ExamSubmissionModel.fromJson(map);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Load answers and questions for a submission review
  Future<List<Map<String, dynamic>>> loadSubmissionReview(String submissionId) async {
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
}
