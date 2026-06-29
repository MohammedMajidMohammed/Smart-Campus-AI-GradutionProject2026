import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:smart_canvas/features/professor/assignments/services/assignments_service.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_assignment_state.dart';

class StudentAssignmentCubit extends Cubit<StudentAssignmentState> {
  final AssignmentsService _service = getIt<AssignmentsService>();
  RealtimeChannel? _assignmentsChannel;
  final _supabase = Supabase.instance.client;

  StudentAssignmentCubit() : super(StudentAssignmentInitial());

  Future<void> loadStudentAssignments() async {
    emit(StudentAssignmentLoading());
    try {
      final assignments = await _service.getStudentUpcomingAssignments();
      emit(StudentAssignmentLoaded(assignments));
    } catch (e) {
      emit(StudentAssignmentError(e.toString()));
    }
  }

  Future<void> submitAssignment({
    required String assignmentId,
    required File file,
    required String fileExt,
  }) async {
    final currentState = state;
    emit(StudentAssignmentLoading());
    try {
      final submission = await _service.submitAssignment(
        assignmentId: assignmentId,
        file: file,
        fileExt: fileExt,
      );
      
      if (submission != null) {
        emit(StudentAssignmentSubmitSuccess('Assignment submitted successfully!'));
        await loadStudentAssignments(); // Refresh list to reflect submission if needed
      } else {
        emit(StudentAssignmentError('Failed to submit assignment.'));
        if (currentState is StudentAssignmentLoaded) {
          emit(currentState);
        }
      }
    } catch (e) {
      emit(StudentAssignmentError(e.toString()));
      if (currentState is StudentAssignmentLoaded) {
        emit(currentState);
      }
    }
  }

  /// Subscribe to realtime updates for assignments
  void subscribeToAssignments() {
    loadStudentAssignments(); // Initial load

    _assignmentsChannel = _supabase.channel('public:student_assignments')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'assignments',
          callback: (payload) {
            loadStudentAssignments();
          },
        )
        .subscribe();
  }

  @override
  Future<void> close() {
    if (_assignmentsChannel != null) {
      _supabase.removeChannel(_assignmentsChannel!);
    }
    return super.close();
  }
}
