part of 'subjects_cubit.dart';

@immutable
sealed class SubjectsState {}

final class SubjectsInitial extends SubjectsState {}
final class GetSubjectsLoading extends SubjectsState {}
final class GetSubjectsSuccess extends SubjectsState {}
final class GetSubjectsFailure extends SubjectsState {
  final String message;
  GetSubjectsFailure({required this.message});
}