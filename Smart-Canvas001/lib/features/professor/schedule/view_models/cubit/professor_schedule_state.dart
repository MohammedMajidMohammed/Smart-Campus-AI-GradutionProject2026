part of 'professor_schedule_cubit.dart';

@immutable
sealed class SchedulesState {}

final class SchedulesInitial extends SchedulesState {}
final class GetSchedulesLoading extends SchedulesState {}
final class GetSchedulesSuccess extends SchedulesState {}
final class GetSchedulesFailure extends SchedulesState {
  final String message;
  GetSchedulesFailure({required this.message});
}