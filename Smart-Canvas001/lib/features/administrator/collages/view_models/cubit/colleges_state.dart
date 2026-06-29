part of 'colleges_cubit.dart';

@immutable
sealed class CollegesState {}

final class CollegesInitial extends CollegesState {}
final class GetCollegesLoading extends CollegesState {}
final class GetCollegesSuccess extends CollegesState {}
final class GetCollegesError extends CollegesState {
  final String message;
  GetCollegesError({required this.message});
}