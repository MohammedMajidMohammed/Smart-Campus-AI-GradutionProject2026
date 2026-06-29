part of 'exams_cubit.dart';

abstract class ExamsState {}

class ExamsInitial extends ExamsState {}

class ExamsLoading extends ExamsState {}

class ExamsLoaded extends ExamsState {
  final List<ExamModel> exams;
  ExamsLoaded(this.exams);
}

class ExamsError extends ExamsState {
  final String message;
  ExamsError(this.message);
}

class ExamCreated extends ExamsState {
  final String examId;
  ExamCreated(this.examId);
}
