part of 'sign_in_cubit.dart';

@immutable
sealed class SignInState {}

final class SignInInitial extends SignInState {}

final class SignInLoading extends SignInState {}

final class SignInSuccess extends SignInState {
  final String route;
  SignInSuccess({required this.route});
}

final class SignInFailure extends SignInState {
  final String message;
  SignInFailure({required this.message});
}

//
final class SignInWithGoogleLoading extends SignInState {}

final class SignInWithGoogleSuccess extends SignInState {
  final String route;
  SignInWithGoogleSuccess({required this.route});
}

final class SignInWithGoogleFailure extends SignInState {
  final String message;
  SignInWithGoogleFailure({required this.message});
}
