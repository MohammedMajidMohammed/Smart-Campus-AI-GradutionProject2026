part of 'add_subject_cubit.dart';

@immutable
sealed class AddSubjectState {}

final class AddSubjectInitial extends AddSubjectState {}
final class AddSubjectLoading extends AddSubjectState {}

final class AddSubjectSuccess extends AddSubjectState {}

final class AddSubjectError extends AddSubjectState {
  final String message;
  AddSubjectError({required this.message});
}

// pick image state
final class SelectSubjectImage extends AddSubjectState {}

final class PickImageSuccess extends AddSubjectState {}

final class PickImageError extends AddSubjectState {
  final String message;
  PickImageError({required this.message});
}

//
final class SelectLocation extends AddSubjectState {}

//
final class SelectCollege extends AddSubjectState {}

//
final class GetCollegesSuccess extends AddSubjectState {}

final class GetCollegesError extends AddSubjectState {
  final String message;
  GetCollegesError({required this.message});
}

final class GetCollegesLoading extends AddSubjectState {}

final class SelectAcademicYear extends AddSubjectState {}
final class AcademicYearsUpdated extends AddSubjectState {}
final class GetAcademicYearsSuccess extends AddSubjectState {}