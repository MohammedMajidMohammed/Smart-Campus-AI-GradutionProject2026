part of 'navigation_cubit.dart';

@immutable
abstract class NavigationState {}

class NavigationInitial extends NavigationState {}

class NavigationActive extends NavigationState {
  final String instruction;
  final bool isSpeaking;
  NavigationActive({this.instruction = "Initializing...", this.isSpeaking = false});
}

class NavigationError extends NavigationState {
  final String message;
  NavigationError(this.message);
}
