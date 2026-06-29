import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class CustomOutLineButton extends StatelessWidget {
  const CustomOutLineButton({
    super.key,
    required this.name,
    this.onPressed,
    this.textStyle,
    this.hPadding,
    this.wPadding,
    this.height,
    this.width,
 this.backgroundColor, this.borderColor, this.borderRadius,
  });
  final String name;
  final Function()? onPressed;
  final TextStyle? textStyle;
  final double? hPadding, wPadding;
  final double? height, width;
  final Color ? backgroundColor;
  final Color ? borderColor;
  final double ? borderRadius;
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 12),
          side: BorderSide(color:borderColor ?? Colors.grey, width: 1.5),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.width * 0.01,
          vertical: SizeConfig.height * 0.001,
        ),
        side: BorderSide(color:borderColor ?? Colors.white, width: 1.5),
        minimumSize: Size(
          width ?? double.infinity,
          height ?? SizeConfig.height * 0.05,
        ),
      ),
      onPressed: onPressed,
      child: Text(
        name,
        style:
            textStyle ??
            AppTextStyles.title18WhiteBold,
      ),
    );
  }
}
