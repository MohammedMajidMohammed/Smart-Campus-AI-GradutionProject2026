import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/components/glass_box.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';

class CustomHeader extends StatelessWidget {
  const CustomHeader({super.key, this.icon, this.title, this.child});
  final String? title;
  final IconData? icon;
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    return GlassBox(
      color: AppColors.kPrimaryColor.withValues(alpha: 0.2),
      borderRadius: 32,
      borderOpacity: 0.2,
      blur: 20,
      width: double.infinity,
      child: SafeArea(
        child: child ??
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title ?? "",
                  style: AppTextStyles.title24WhiteW500,
                ),
                Icon(
                  icon,
                  color: Colors.white,
                  size: SizeConfig.height * 0.04,
                ),
              ],
            ),
      ),
    );
  }
}
