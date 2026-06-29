part of 'regulations_chatbot_cubit.dart';

@immutable
sealed class RegulationsChatbotState {}

final class RegulationsChatbotInitial extends RegulationsChatbotState {}

final class ChatbotThinking extends RegulationsChatbotState {}

final class ChatbotError extends RegulationsChatbotState {
  final String message;
  ChatbotError({required this.message});
}

final class ChatbotLoaded extends RegulationsChatbotState {}

