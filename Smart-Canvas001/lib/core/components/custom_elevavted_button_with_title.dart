import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';

class CustomElevatedButtonWithIcon extends StatelessWidget {
  const CustomElevatedButtonWithIcon({
    super.key,
    required this.title,
    this.onPressed,
    this.icon,
    this.textStyle,
    this.image,
    this.backgroundColor,
    this.iconAlignment,
    this.height,
    this.width,
  });

  final String title;
  final Function()? onPressed;
  final TextStyle? textStyle;
  final String? image;
  final IconData? icon;
  final Color? backgroundColor;
  final IconAlignment? iconAlignment;
  final double? height, width;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.kPrimaryColor, // شفاف عشان يبان الجريدينت
        shadowColor: Colors.transparent, // مفيش ظل افتراضي
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: context.screenWidth * 0.06,
          vertical: context.screenHeight * 0.012,
        ),
        minimumSize: (height != null && width != null)
            ? Size(width!, height!)
            : Size(double.infinity, context.screenHeight * 0.075),
      ),
      iconAlignment: iconAlignment ?? IconAlignment.end,
      onPressed: onPressed,
      icon: icon == null
          ? const SizedBox()
          : Icon(
              icon,
              color: Colors.white,
              size: SizeConfig.width * 0.065,
            ),
      label: Text(
        title,
        style: textStyle ?? AppTextStyles.title18WhiteW500,
      ),
    );
  }
}
