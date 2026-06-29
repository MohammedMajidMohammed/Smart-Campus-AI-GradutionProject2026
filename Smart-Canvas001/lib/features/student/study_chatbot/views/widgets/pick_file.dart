import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:smart_canvas/features/student/study_chatbot/view_models/cubit/study_chatbot_cubit.dart';
import 'package:smart_canvas/features/student/study_chatbot/views/widgets/fancy_button.dart'; // للأنيميشن إذا لزم الأمر

class PickFile extends StatelessWidget {
  const PickFile({super.key, required this.cubit});

  final StudyChatbotCubit cubit;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          builder: (_) => AnimatedPadding(
            padding: MediaQuery.of(context).viewInsets,
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: SizeConfig.width,
              height: SizeConfig.height * 0.3,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.width * 0.03,
                  vertical: SizeConfig.height * 0.01,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: EdgeInsets.only(
                        top: SizeConfig.height * 0.02,
                        bottom: SizeConfig.height * 0.03,
                      ),
                      width: SizeConfig.width * 0.1,
                      height: SizeConfig.height * 0.005,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 500),
                      style: AppTextStyles.title24PrimaryColorW500,
                      child: const Text(
                        "Choose Attachment",
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: SizeConfig.height * 0.02),
                    Row(
                      children: [
                        Expanded(
                          child: FancyButton(
                            icon: Icons.image,
                            label: "Image",
                            color: const Color(0xFF1E8449),
                            onTap: () {
                              context.popScreen();
                              cubit.pickImageFromGallery();
                            },
                          ),
                        ),
                        SizedBox(width: SizeConfig.width * 0.03),
                        Expanded(
                          child: FancyButton(
                            icon: Icons.insert_drive_file,
                            label: "File",
                            color: Colors.green,
                            onTap: () {
                              context.popScreen();
                              cubit.pickFile();
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.height * 0.03),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      icon: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.width * 0.02,
          vertical: SizeConfig.height * 0.01,
        ),
        decoration: BoxDecoration(
          color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.kPrimaryColor.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.attach_file_rounded,
          color: AppColors.kPrimaryColor,
          size: SizeConfig.width * 0.06,
        ),
      ),
    );
  }
}
