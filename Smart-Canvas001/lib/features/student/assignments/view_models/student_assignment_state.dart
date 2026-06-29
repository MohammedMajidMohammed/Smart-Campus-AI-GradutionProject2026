import 'package:flutter/foundation.dart';
import 'package:smart_canvas/features/professor/assignments/models/assignment_model.dart';

@immutable
abstract class StudentAssignmentState {}

class StudentAssignmentInitial extends StudentAssignmentState {}

class StudentAssignmentLoading extends StudentAssignmentState {}

class StudentAssignmentLoaded extends StudentAssignmentState {
  final List<AssignmentModel> assignments;
  StudentAssignmentLoaded(this.assignments);
}

class StudentAssignmentError extends StudentAssignmentState {
  final String message;
  StudentAssignmentError(this.message);
}

class StudentAssignmentSubmitSuccess extends StudentAssignmentState {
  final String message;
  StudentAssignmentSubmitSuccess(this.message);
}
