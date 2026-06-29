import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class CustomOutLineButtonWithImage extends StatelessWidget {
  const CustomOutLineButtonWithImage({
    super.key,
    required this.name,
    this.onPressed,
    this.textStyle,
    this.hPadding,
    this.wPadding,
    this.height,
    this.width,
    required this.image, this.backgroundColor, this.borderColor, this.borderRadius,
  });
  final String name, image;
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
        backgroundColor:backgroundColor ?? Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 16),
          side: BorderSide(color:borderColor ?? Colors.grey, width: 1.5),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.width * 0.05,
          vertical: SizeConfig.height * 0.003,
        ),
        side: BorderSide(color:borderColor ?? Colors.grey.shade500, width: 2),
        minimumSize: Size(
          width ?? double.infinity,
          height ?? SizeConfig.height * 0.07,
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: hPadding ?? SizeConfig.width * 0.005,
              vertical: wPadding ?? SizeConfig.height * 0.007,
            ),
            width: SizeConfig.width * 0.12,
            padding: EdgeInsets.symmetric(
              horizontal: hPadding ?? SizeConfig.width * 0.024,
              vertical: wPadding ?? SizeConfig.height * 0.009,
            ),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Image.asset(image),
          ),
          Text(
            name,
            style:
                textStyle ??
                AppTextStyles.title20WhiteBold.copyWith(color: Colors.black),
          ),
        ],
      ),
    );
  }
}
