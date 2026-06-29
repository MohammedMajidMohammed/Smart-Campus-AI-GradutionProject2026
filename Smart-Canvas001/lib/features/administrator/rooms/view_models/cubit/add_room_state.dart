part of 'add_room_cubit.dart';

@immutable
sealed class AddRoomState {}

final class AddRoomInitial extends AddRoomState {}

final class AddRoomLoading extends AddRoomState {}

final class AddRoomSuccess extends AddRoomState {}

final class AddRoomError extends AddRoomState {
  final String message;
  AddRoomError({required this.message});
}

// pick image state
final class SelectRoomImage extends AddRoomState {}

final class PickImageSuccess extends AddRoomState {}

final class PickImageError extends AddRoomState {
  final String message;
  PickImageError({required this.message});
}

//
final class SelectLocation extends AddRoomState {}

//
final class SelectBuilding extends AddRoomState {}

//
final class GetBuildingsSuccess extends AddRoomState {}

final class GetBuildingsError extends AddRoomState {
  final String message;
  GetBuildingsError({required this.message});
}

final class GetBuildingsLoading extends AddRoomState {}

final class SelectRoomType extends AddRoomState {}

// current location state
final class GetCurrentLocationLoading extends AddRoomState {}

final class GetCurrentLocationSuccess extends AddRoomState {}

final class GetCurrentLocationError extends AddRoomState {
  final String message;
  GetCurrentLocationError({required this.message});
}
final class AddMarkerSuccess extends AddRoomState {}