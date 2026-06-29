part of 'professor_attendance_cubit.dart';

@immutable
abstract class ProfessorAttendanceState {}

class ProfessorAttendanceInitial extends ProfessorAttendanceState {}

class ProfessorAttendanceLoading extends ProfessorAttendanceState {}

class GetSubjectsSuccess extends ProfessorAttendanceState {
  final List<SubjectModel> subjects;
  GetSubjectsSuccess({required this.subjects});
}

class ProfessorAttendanceStarted extends ProfessorAttendanceState {
  final String token;
  final String pin;
  final int attendeeCount;

  ProfessorAttendanceStarted({
    required this.token,
    required this.pin,
    required this.attendeeCount,
  });
}

class ProfessorAttendanceError extends ProfessorAttendanceState {
  final String message;
  ProfessorAttendanceError({required this.message});
}
