import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:smart_canvas/features/professor/assignments/models/assignment_model.dart';
import 'package:smart_canvas/features/professor/assignments/services/assignments_service.dart';
import 'doctor_assignment_state.dart';

class DoctorAssignmentCubit extends Cubit<DoctorAssignmentState> {
  final AssignmentsService _service;
  
  DoctorAssignmentCubit(this._service) : super(DoctorAssignmentInitial());

  Future<void> loadAssignmentsAndSubjects() async {
    emit(DoctorAssignmentLoading());
    try {
      final assignments = await _service.getProfessorAssignments();
      final subjects = await _service.getProfessorSubjects();
      emit(DoctorAssignmentLoaded(assignments, subjects));
    } catch (e) {
      emit(DoctorAssignmentError(e.toString()));
    }
  }

  Future<void> addAssignment(AssignmentModel assignment, File? file, String? fileExt) async {
    final currentState = state;
    emit(DoctorAssignmentLoading());
    try {
      final created = await _service.createAssignment(assignment, file, fileExt);
      if (created != null) {
        emit(DoctorAssignmentActionSuccess('Assignment created successfully!'));
        await loadAssignmentsAndSubjects(); // Refresh
      } else {
        emit(DoctorAssignmentError('Failed to create assignment.'));
        if (currentState is DoctorAssignmentLoaded) {
          emit(currentState);
        }
      }
    } catch (e) {
      emit(DoctorAssignmentError(e.toString()));
      if (currentState is DoctorAssignmentLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> editAssignment(AssignmentModel assignment, File? file, String? fileExt) async {
    final currentState = state;
    emit(DoctorAssignmentLoading());
    try {
      final updated = await _service.updateAssignment(assignment, file, fileExt);
      if (updated != null) {
        emit(DoctorAssignmentActionSuccess('Assignment updated successfully!'));
        await loadAssignmentsAndSubjects(); // Refresh
      } else {
        emit(DoctorAssignmentError('Failed to update assignment.'));
        if (currentState is DoctorAssignmentLoaded) {
          emit(currentState);
        }
      }
    } catch (e) {
      emit(DoctorAssignmentError(e.toString()));
      if (currentState is DoctorAssignmentLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> deleteAssignment(String id) async {
    final currentState = state;
    emit(DoctorAssignmentLoading());
    try {
      final success = await _service.deleteAssignment(id);
      if (success) {
        emit(DoctorAssignmentActionSuccess('Assignment deleted successfully!'));
        await loadAssignmentsAndSubjects(); // Refresh
      } else {
        emit(DoctorAssignmentError('Failed to delete assignment.'));
        if (currentState is DoctorAssignmentLoaded) {
          emit(currentState);
        }
      }
    } catch (e) {
      emit(DoctorAssignmentError(e.toString()));
      if (currentState is DoctorAssignmentLoaded) {
        emit(currentState);
      }
    }
  }
}
