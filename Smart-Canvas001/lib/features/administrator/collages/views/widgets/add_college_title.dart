import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';

class AddTitle extends StatelessWidget {
  const AddTitle({super.key, required this.icon, required this.title});
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Container(
            margin: EdgeInsets.only(bottom: SizeConfig.height * 0.01),
            width: SizeConfig.width * 0.1,
            height: SizeConfig.height * 0.005,
            decoration: BoxDecoration(
              color: AppColors.kPrimaryColor.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        SizedBox(height: SizeConfig.height * 0.02),
        Center(
          child: Column(
            children: [
              Icon(
                icon,
                size: SizeConfig.width * 0.12,
                color: AppColors.kPrimaryColor,
              ),
              SizedBox(height: SizeConfig.height * 0.01),
              Text(title, style: AppTextStyles.title24BlackW700),
            ],
          ),
        ),
      ],
    );
  }
}
