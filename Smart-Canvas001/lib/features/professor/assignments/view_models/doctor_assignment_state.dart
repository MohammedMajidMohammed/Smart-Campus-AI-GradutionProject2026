import 'package:flutter/foundation.dart';
import 'package:smart_canvas/features/professor/assignments/models/assignment_model.dart';
import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';

@immutable
abstract class DoctorAssignmentState {}

class DoctorAssignmentInitial extends DoctorAssignmentState {}

class DoctorAssignmentLoading extends DoctorAssignmentState {}

class DoctorAssignmentLoaded extends DoctorAssignmentState {
  final List<AssignmentModel> assignments;
  final List<SubjectModel> subjects;

  DoctorAssignmentLoaded(this.assignments, this.subjects);
}

class DoctorAssignmentActionSuccess extends DoctorAssignmentState {
  final String message;
  DoctorAssignmentActionSuccess(this.message);
}

class DoctorAssignmentError extends DoctorAssignmentState {
  final String message;

  DoctorAssignmentError(this.message);
}
