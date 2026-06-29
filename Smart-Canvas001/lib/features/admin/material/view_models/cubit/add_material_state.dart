part of 'add_material_cubit.dart';

@immutable
sealed class AddMaterialState {}

final class AddMaterialInitial extends AddMaterialState {}
final class AddMaterialLoading extends AddMaterialState {}

final class AddMaterialSuccess extends AddMaterialState {}

final class AddMaterialError extends AddMaterialState {
  final String message;
  AddMaterialError({required this.message});
}

// pick image state
final class SelectMaterialImage extends AddMaterialState {}

final class PickImageSuccess extends AddMaterialState {}

final class PickImageError extends AddMaterialState {
  final String message;
  PickImageError({required this.message});
}

//
final class SelectLocation extends AddMaterialState {}

//
final class SelectSubject extends AddMaterialState {}

//
final class GetSubjectsSuccess extends AddMaterialState {}

final class GetSubjectsError extends AddMaterialState {
  final String message;
  GetSubjectsError({required this.message});
}

final class GetSubjectsLoading extends AddMaterialState {}

final class SelectAcademicYear extends AddMaterialState {}
final class AcademicYearsUpdated extends AddMaterialState {}
final class GetAcademicYearsSuccess extends AddMaterialState {}

// File picker states
final class FileSelected extends AddMaterialState {}
final class FileCleared extends AddMaterialState {}