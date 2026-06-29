part of 'rooms_cubit.dart';

@immutable
sealed class RoomsState {}

final class RoomsInitial extends RoomsState {}
final class GetRoomsLoading extends RoomsState {}
final class GetRoomsSuccess extends RoomsState {}
final class GetRoomsFailure extends RoomsState {
  final String message;
  GetRoomsFailure({required this.message});
}
final class DeleteRoomLoading extends RoomsState {}
final class DeleteRoomSuccess extends RoomsState {}
final class DeleteRoomFailure extends RoomsState {
  final String message;
  DeleteRoomFailure({required this.message});
}