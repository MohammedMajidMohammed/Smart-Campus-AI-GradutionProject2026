part of 'subject_chat_cubit.dart';

abstract class SubjectChatState extends Equatable {
  const SubjectChatState();

  @override
  List<Object?> get props => [];
}

class SubjectChatInitial extends SubjectChatState {}

class SubjectChatLoading extends SubjectChatState {}

class SubjectChatLoaded extends SubjectChatState {
  final List<SubjectMessageModel> messages;
  final SubjectMessageModel? editingMessage;
  final Map<String, String> typingUsers; // userId -> userName

  const SubjectChatLoaded(
    this.messages, {
    this.editingMessage,
    this.typingUsers = const {},
  });

  @override
  List<Object?> get props => [messages, editingMessage, typingUsers];
}

class SubjectChatEditing extends SubjectChatLoaded {
  const SubjectChatEditing(
    super.messages, {
    required super.editingMessage,
    super.typingUsers = const {},
  });
}

class SubjectChatError extends SubjectChatState {
  final String message;
  const SubjectChatError(this.message);

  @override
  List<Object?> get props => [message];
}

class SubjectChatUploading extends SubjectChatState {
  final double progress;
  const SubjectChatUploading({this.progress = 0});

  @override
  List<Object?> get props => [progress];
}
