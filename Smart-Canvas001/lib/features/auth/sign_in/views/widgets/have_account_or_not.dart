import 'package:flutter/material.dart';
import 'package:smart_canvas/core/components/custom_text_button.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';

class HaveAccountOrNot extends StatelessWidget {
  const HaveAccountOrNot({
    super.key,
    required this.title,
    required this.value,
    required this.onPressed,
  });
  final String title, value;
  final Function()? onPressed;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: AppTextStyles.title18Black,
        ),
        CustomTextButton(
          title: value,
          style: AppTextStyles.title18kPrimaryColorBold,
          onPressed: onPressed,
        ),
      ],
    );
  }
}
