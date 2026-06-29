import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:smart_canvas/features/student/study_chatbot/view_models/cubit/study_chatbot_cubit.dart';
import 'package:easy_localization/easy_localization.dart';

class ChatBotTextField extends StatelessWidget {
  const ChatBotTextField({super.key, required this.cubit});

  final StudyChatbotCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudyChatbotCubit, StudyChatbotState>(
      buildWhen: (previous, current) =>
          current is ChatbotThinking || previous is ChatbotThinking,
      builder: (context, state) {
        return Expanded(
          child: TextField(
            controller: cubit.messageTextcontroller,
            enabled: state is! ChatbotThinking,
            decoration: InputDecoration(
              hintText: 'ask_anything_hint'.tr(),
              hintStyle: AppTextStyles.title16GreyW500,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                vertical: SizeConfig.height * 0.02,
              ),
            ),
            maxLines: null,
            style: AppTextStyles.title16Black,
          ),
        );
      },
    );
  }
}
