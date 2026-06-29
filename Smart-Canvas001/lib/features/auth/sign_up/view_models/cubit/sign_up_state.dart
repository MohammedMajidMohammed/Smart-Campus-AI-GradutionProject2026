part of 'sign_up_cubit.dart';

@immutable
sealed class SignUpState {}

final class SignUpInitial extends SignUpState {}

final class SignUpLoading extends SignUpState {}

final class SignUpSuccess extends SignUpState {
  final String route;
  SignUpSuccess({required this.route});
}

final class SignUpFailure extends SignUpState {
  final String errorMessage;
  SignUpFailure({required this.errorMessage});
}

// pick image
final class PickImageLoading extends SignUpState {}

final class PickImageSuccess extends SignUpState {}

final class PickImageFailure extends SignUpState {
  final String errorMessage;
  PickImageFailure({required this.errorMessage});
}

final class SelectImage extends SignUpState {}

// sign up with google
final class SignUpWithGoogleLoading extends SignUpState {}

final class SignUpWithGoogleSuccess extends SignUpState {}

final class SignUpWithGoogleFailure extends SignUpState {
  final String errorMessage;
  SignUpWithGoogleFailure({required this.errorMessage});
}

final class SetAddress extends SignUpState {}

// colleges state
final class GetCollegesLoading extends SignUpState {}

final class GetCollegesSuccess extends SignUpState {}

final class GetCollegesFailure extends SignUpState {
  final String errorMessage;
  GetCollegesFailure({required this.errorMessage});
}

final class AcademicYearsUpdated extends SignUpState {}
final class GetAcademicYearsSuccess extends SignUpState {}
