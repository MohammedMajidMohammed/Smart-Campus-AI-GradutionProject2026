import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';

class HelperMessage extends StatelessWidget {
  const HelperMessage({
    super.key,
    required this.message,
    required this.onSend,
    this.isRegulations = false,
  });

  final String message;
  final VoidCallback? onSend;
  final bool isRegulations;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor = AppColors.kPrimaryColor;
    
    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: SizeConfig.width * 0.035,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.4,
            ),
          ),
        ),
        SizedBox(width: SizeConfig.width * 0.03),
        GestureDetector(
          onTap: onSend,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: themeColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: SizeConfig.width * 0.045,
            ),
          ),
        ),
      ],
    );
  }
}
