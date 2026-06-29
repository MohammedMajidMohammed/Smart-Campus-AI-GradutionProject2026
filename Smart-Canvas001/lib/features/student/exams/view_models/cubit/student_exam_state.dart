part of 'student_exam_cubit.dart';

abstract class StudentExamState {}

class StudentExamInitial extends StudentExamState {}

class StudentExamLoading extends StudentExamState {}

class StudentExamsLoaded extends StudentExamState {
  final List<ExamModel> available;
  final List<Map<String, dynamic>> completed;
  StudentExamsLoaded({required this.available, required this.completed});
}

class StudentExamError extends StudentExamState {
  final String message;
  StudentExamError(this.message);
}
