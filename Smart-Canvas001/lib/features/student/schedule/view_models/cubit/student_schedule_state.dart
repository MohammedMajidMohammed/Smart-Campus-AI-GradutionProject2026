part of 'student_schedule_cubit.dart';

@immutable
sealed class StudentScheduleState {}

final class StudentScheduleInitial extends StudentScheduleState {}

final class StudentScheduleLoading extends StudentScheduleState {}

final class StudentScheduleError extends StudentScheduleState {
  final String message;
  StudentScheduleError({required this.message});
}

final class StudentScheduleLoaded extends StudentScheduleState {}