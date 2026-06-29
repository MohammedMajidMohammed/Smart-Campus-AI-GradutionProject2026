part of 'add_building_cubit.dart';

@immutable
sealed class AddBuildingState {}

final class AddBuildingInitial extends AddBuildingState {}

final class AddBuildingLoading extends AddBuildingState {}

final class AddBuildingSuccess extends AddBuildingState {}

final class AddBuildingError extends AddBuildingState {
  final String message;
  AddBuildingError({required this.message});
}

// pick image state
final class SelectBuildingImage extends AddBuildingState {}

final class PickImageSuccess extends AddBuildingState {}

final class PickImageError extends AddBuildingState {
  final String message;
  PickImageError({required this.message});
}

//
final class SelectLocation extends AddBuildingState {}

//
final class SelectCollege extends AddBuildingState {}

//
final class GetCollegesSuccess extends AddBuildingState {}

final class GetCollegesError extends AddBuildingState {
  final String message;
  GetCollegesError({required this.message});
}

final class GetCollegesLoading extends AddBuildingState {}

final class SelectBuildingType extends AddBuildingState {}

// current location state
final class GetCurrentLocationLoading extends AddBuildingState {}

final class GetCurrentLocationSuccess extends AddBuildingState {}

final class GetCurrentLocationError extends AddBuildingState {
  final String message;
  GetCurrentLocationError({required this.message});
}
final class AddMarkerSuccess extends AddBuildingState {}