part of 'add_subject_schedule_cubit.dart';

@immutable
sealed class AddSubjectScheduleState {}

final class AddSubjectScheduleInitial extends AddSubjectScheduleState {}

final class AddSubjectScheduleLoading extends AddSubjectScheduleState {}

final class AddSubjectScheduleSuccess extends AddSubjectScheduleState {}

final class AddSubjectScheduleError extends AddSubjectScheduleState {
  final String message;
  AddSubjectScheduleError({required this.message});
}
final class SubjectScheduleAlreadyExists extends AddSubjectScheduleState {}
// subject state
final class GetSubjectsSuccess extends AddSubjectScheduleState {}

final class GetSubjectsError extends AddSubjectScheduleState {
  final String message;
  GetSubjectsError({required this.message});
}

final class GetSubjectsLoading extends AddSubjectScheduleState {}

final class SelectSubject extends AddSubjectScheduleState {}

final class SelectDay extends AddSubjectScheduleState {}

final class UpdateDayOfWeek extends AddSubjectScheduleState {}

final class SelectTimeSlot extends AddSubjectScheduleState {}

final class UpdateTimeSlot extends AddSubjectScheduleState {}

//
final class GetDoctorsSuccess extends AddSubjectScheduleState {}

final class GeDoctorsError extends AddSubjectScheduleState {
  final String message;
  GeDoctorsError({required this.message});
}

final class GetDoctorsLoading extends AddSubjectScheduleState {}

final class SelectDoctor extends AddSubjectScheduleState {}

// College States
final class GetCollegesLoading extends AddSubjectScheduleState {}
final class GetCollegesSuccess extends AddSubjectScheduleState {}
final class GetCollegesError extends AddSubjectScheduleState {
  final String message;
  GetCollegesError({required this.message});
}
final class UpdateCollegeSelection extends AddSubjectScheduleState {}
final class SelectCollege extends AddSubjectScheduleState {}

// Program States
final class UpdateProgramSelection extends AddSubjectScheduleState {}
final class SelectProgram extends AddSubjectScheduleState {}

// Year States
final class UpdateYearSelection extends AddSubjectScheduleState {}
final class SelectYear extends AddSubjectScheduleState {}
