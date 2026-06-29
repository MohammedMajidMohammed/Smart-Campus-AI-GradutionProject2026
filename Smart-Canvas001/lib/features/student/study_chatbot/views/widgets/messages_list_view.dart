import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/constants/app_constants.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/student/study_chatbot/models/message_model.dart';
import 'package:smart_canvas/features/student/study_chatbot/view_models/cubit/study_chatbot_cubit.dart';
import 'package:smart_canvas/features/student/study_chatbot/views/widgets/chat_message_bubble.dart';
import 'package:smart_canvas/features/student/study_chatbot/views/widgets/chat_thinking_bubble.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/core/utilies/assets/images/app_images.dart';

class MessagesListView extends StatefulWidget {
  const MessagesListView({super.key, required this.cubit});

  final StudyChatbotCubit cubit;

  @override
  State<MessagesListView> createState() => _MessagesListViewState();
}

class _MessagesListViewState extends State<MessagesListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    // Use a post-frame callback to ensure the list has been rebuilt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      // Animate smoothly to the very bottom
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StudyChatbotCubit, StudyChatbotState>(
      listener: (context, state) {
        _scrollToBottom();
      },
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        if (widget.cubit.messages.isEmpty) {
          var helperMessage = AppConstants.chatbotHelperMessage;
          return Stack(
            children: [
              Center(
                child: Opacity(
                  opacity: isDark ? 0.04 : 0.07,
                  child: Image.asset(
                    AppImages.logoWithoutBackgroundImage,
                    width: MediaQuery.of(context).size.width * 0.72,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                itemCount: helperMessage.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                      child: Column(
                        children: [
                          // Premium Robot Icon
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : AppColors.kPrimaryColor.withValues(alpha: 0.08),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.kPrimaryColor.withValues(alpha: 0.15),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              LineIcons.robot,
                              size: 56,
                              color: isDark ? Colors.white : AppColors.kPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Title
                          Text(
                            "welcome_study_ai".tr(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.kPrimaryColor,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          // Subtitle
                          Text(
                            "study_ai_desc".tr(),
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white54 : Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  final helperMessageText =
                      AppConstants.chatbotHelperMessage[index - 1];
                  return ChatMessageBubble(
                    key: ValueKey(index),
                    message: MessageModel(message: helperMessageText, isUser: true),
                    isHelperMessage: true,
                    onSend: () {
                      widget.cubit.messageTextcontroller.text = helperMessageText;
                      widget.cubit.sendMessage();
                    },
                  );
                },
              ),
            ],
          );
        }
        final itemCount =
            widget.cubit.messages.length + (state is ChatbotThinking ? 1 : 0) + (state is ChatbotError ? 1 : 0);
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (state is ChatbotThinking && index == widget.cubit.messages.length) {
              return const ChatThinkingBubble();
            }
            if (state is ChatbotError && index == widget.cubit.messages.length) {
              return _buildErrorBubble(context, state.message);
            }
            final message = widget.cubit.messages[index];
            return ChatMessageBubble(
              onSend: () {
                widget.cubit.sendMessage();
              },
              message: message,
            );
          },
        );
      },
    );
  }

  Widget _buildErrorBubble(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message,
                  style: TextStyle(
                    color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
