part of 'online_sessions_cubit.dart';

abstract class OnlineSessionsState extends Equatable {
  const OnlineSessionsState();

  @override
  List<Object?> get props => [];
}

class OnlineSessionsInitial extends OnlineSessionsState {}

class OnlineSessionsLoading extends OnlineSessionsState {}

class OnlineSessionsLoaded extends OnlineSessionsState {
  final List<OnlineSessionModel> sessions;
  const OnlineSessionsLoaded(this.sessions);

  @override
  List<Object?> get props => [sessions];
}

class OnlineSessionsError extends OnlineSessionsState {
  final String message;
  const OnlineSessionsError(this.message);

  @override
  List<Object?> get props => [message];
}

class OnlineSessionsCreated extends OnlineSessionsState {
  final OnlineSessionModel session;
  const OnlineSessionsCreated(this.session);

  @override
  List<Object?> get props => [session];
}

class OnlineSessionsSubjectsLoaded extends OnlineSessionsState {
  final List<SubjectModel> subjects;
  const OnlineSessionsSubjectsLoaded(this.subjects);

  @override
  List<Object?> get props => [subjects];
}
