part of 'college_data_cubit.dart';

@immutable
abstract class CollegeDataState {
  const CollegeDataState();

}

class CollegeDataInitial extends CollegeDataState {}

class CollegeDataLoading extends CollegeDataState {}

class CollegeDataSuccess extends CollegeDataState {
}

class CollegeDataFailure extends CollegeDataState {
  final String error;

  const CollegeDataFailure(this.error);

}