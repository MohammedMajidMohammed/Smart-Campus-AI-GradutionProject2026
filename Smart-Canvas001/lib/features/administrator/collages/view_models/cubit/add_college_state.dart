part of 'add_college_cubit.dart';

@immutable
sealed class AddCollegeState {}

final class AddCollegeInitial extends AddCollegeState {}

final class AddCollegeLoading extends AddCollegeState {}

final class AddCollegeSuccess extends AddCollegeState {}

final class AddCollegeError extends AddCollegeState {
  final String message;
  AddCollegeError({required this.message});
}

//--> pick image state
final class PickImageSuccess extends AddCollegeState {}

final class PickImageError extends AddCollegeState {
  final String message;
  PickImageError({required this.message});
}

final class SelectCollageImage extends AddCollegeState {}

// academic years states
class AcademicYearsUpdated extends AddCollegeState {}

// get academic years states
final class GetAcademicYearsLoading extends AddCollegeState {}

final class GetAcademicYearsSuccess extends AddCollegeState {}

final class GetAcademicYearsError extends AddCollegeState {
  final String message;
  GetAcademicYearsError({required this.message});
}
