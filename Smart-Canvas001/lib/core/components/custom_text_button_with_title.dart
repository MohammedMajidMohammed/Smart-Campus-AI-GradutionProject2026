import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:flutter/material.dart';

class CustomTextButtonWithIcon extends StatelessWidget {
  const CustomTextButtonWithIcon({
    super.key, required this.title, required this.icon, this.onPressed,
  });
  final String title;
  final IconData icon;
  final void Function()? onPressed;
  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: SizeConfig.width * 0.05),
      label: Text(title),
      style: TextButton.styleFrom(
        foregroundColor: Colors.black,
        
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.black12),
        ),
      ),
    );
  }
}
