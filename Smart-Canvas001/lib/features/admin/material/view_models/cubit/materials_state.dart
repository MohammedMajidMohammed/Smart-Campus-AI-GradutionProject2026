part of 'materials_cubit.dart';

@immutable
sealed class MaterialsState {}

final class MaterialsInitial extends MaterialsState {}
final class GetMaterialsLoading extends MaterialsState {}
final class GetMaterialsSuccess extends MaterialsState {}
final class GetMaterialsFailure extends MaterialsState {
  final String message;
  GetMaterialsFailure({required this.message});
}
final class AddSubjectSuccess extends MaterialsState {}