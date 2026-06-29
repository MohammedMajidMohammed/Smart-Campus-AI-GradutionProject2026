import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:flutter/material.dart';

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    this.onPressed,
    required this.backgroundColor,
    required this.iconColor,
    required this.icon,
  });
  final Color backgroundColor, iconColor;
  final IconData icon;
  final Function()? onPressed;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor, size: SizeConfig.width * 0.05),
      ),
    );
  }
}
