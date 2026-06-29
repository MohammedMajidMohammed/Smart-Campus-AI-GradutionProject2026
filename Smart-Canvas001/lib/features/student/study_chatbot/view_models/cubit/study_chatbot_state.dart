part of 'study_chatbot_cubit.dart';

@immutable
sealed class StudyChatbotState {}

final class StudyChatbotInitial extends StudyChatbotState {}

final class ChatbotThinking extends StudyChatbotState {}

final class ChatbotError extends StudyChatbotState {
  final String message;
  ChatbotError({required this.message});
}

final class ChatbotLoaded extends StudyChatbotState {}

final class UpdateImage extends StudyChatbotState {}
final class UpdateFile extends StudyChatbotState {}

final class PickImageError extends StudyChatbotState {
  final String message;
  PickImageError({required this.message});
}

final class PickFileError extends StudyChatbotState {
  final String message;
  PickFileError({required this.message});
}