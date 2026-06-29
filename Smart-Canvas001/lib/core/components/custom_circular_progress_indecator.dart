import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:flutter/material.dart';

class CustomCircularProgresIndecator extends StatelessWidget {
  const CustomCircularProgresIndecator({
    super.key,
    this.height,
    this.color,
    this.width,
  });
  final double? height;
  final double? width;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: Center(
        child: CircularProgressIndicator(
          color: color ?? AppColors.kPrimaryColor,
        ),
      ),
    );
  }
}
