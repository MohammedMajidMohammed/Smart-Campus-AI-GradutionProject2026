part of 'buildings_cubit.dart';

@immutable
sealed class BuildingsState {}

final class BuildingsInitial extends BuildingsState {}
final class GetBuildingsLoading extends BuildingsState {}
final class GetBuildingsSuccess extends BuildingsState {}
final class GetBuildingsError extends BuildingsState {
  final String message;
  GetBuildingsError({required this.message});
}