import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/student/study_chatbot/view_models/cubit/study_chatbot_cubit.dart';
import 'package:smart_canvas/features/student/study_chatbot/views/widgets/attachment_preview.dart';
import 'package:smart_canvas/features/student/study_chatbot/views/widgets/chatbot_text_field.dart';
import 'package:smart_canvas/features/student/study_chatbot/views/widgets/pick_file.dart';

class ChatInputBar extends StatelessWidget {
  final StudyChatbotCubit cubit;

  const ChatInputBar({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: SizeConfig.width * 0.04,
        vertical: SizeConfig.height * 0.01,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BlocBuilder<StudyChatbotCubit, StudyChatbotState>(
              buildWhen: (previous, current) =>
                  current is UpdateFile ||
                  current is UpdateImage ||
                  previous is UpdateFile ||
                  previous is UpdateImage,
              builder: (context, state) {
                if (cubit.image == null && cubit.file == null) return const SizedBox();
                return Container(
                  padding: const EdgeInsets.all(8.0),
                  color: isDark ? Colors.black12 : Colors.grey.shade50,
                  child: AttachmentPreview(
                    image: cubit.image,
                    file: cubit.file,
                    onRemoveImage: () => cubit.onRemoveImage(),
                    onRemoveFile: () => cubit.onRemoveFile(),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 4.0),
              child: Row(
                children: [
                  PickFile(cubit: cubit),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChatBotTextField(cubit: cubit),
                    ),
                  ),
                  _buildSendButton(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        gradient: AppColors.studyGradient,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () => cubit.sendMessage(),
        icon: const Icon(
          Icons.send_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}


