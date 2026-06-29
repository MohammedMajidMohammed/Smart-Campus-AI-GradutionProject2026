import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';

class CustomTextButton extends StatelessWidget {
  const CustomTextButton({
    super.key,
    this.onPressed,
    required this.title,
    this.style,
    this.alignment,
    this.backgroundColor,
  });

  final Function()? onPressed;
  final String title;
  final TextStyle? style;
  final AlignmentGeometry? alignment;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment ?? Alignment.topCenter,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: backgroundColor ?? Colors.transparent,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.width * 0.02,
          ),
          child: Text(
            title,
            style: style ?? AppTextStyles.title16PrimaryColorW500,
          ),
        ),
      ),
    );
  }
}
