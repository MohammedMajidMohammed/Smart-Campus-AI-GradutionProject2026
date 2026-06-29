import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/student/regulations_chatbot/view_models/cubit/regulations_chatbot_cubit.dart';
import 'package:easy_localization/easy_localization.dart';

class RegulationsChatInputBar extends StatelessWidget {
  final RegulationsChatbotCubit cubit;

  const RegulationsChatInputBar({super.key, required this.cubit});

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
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 4.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: cubit.messageTextcontroller,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'type_question_hint'.tr(),
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                maxLines: null,
                textInputAction: TextInputAction.newline,
              ),
            ),
            _buildSendButton(isDark),
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

