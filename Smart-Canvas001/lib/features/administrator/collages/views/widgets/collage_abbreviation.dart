import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';

class CollageAbbreviation extends StatelessWidget {
  const CollageAbbreviation({
    super.key,
    required this.collageAbbreviation,
  });

  final String collageAbbreviation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.width * 0.02,
        vertical: SizeConfig.height * 0.005,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        collageAbbreviation,
        style: AppTextStyles.title14White,
      ),
    );
  }
}